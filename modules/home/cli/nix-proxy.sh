# shellcheck shell=bash
set -uo pipefail

readonly PROXY_HOST="@PROXY_HOST@"
readonly DEFAULT_PORT="@PROXY_PORT@"
readonly DROPIN_DIR="/run/systemd/system/nix-daemon.service.d"
readonly DROPIN="$DROPIN_DIR/zz-nix-proxy.conf"
readonly PENDING="$DROPIN.tmp"
readonly BACKUP="$DROPIN.previous"
readonly TEST_URLS=(
  "https://cache.nixos.org/nix-cache-info"
  "https://niri.cachix.org/nix-cache-info"
)
TEMP_FILE=""

cleanup() {
  [[ -z "$TEMP_FILE" ]] || rm -f -- "$TEMP_FILE"
}
trap cleanup EXIT

usage() {
  cat <<'USAGE'
Usage:
  nix-proxy status
  nix-proxy test [PORT] [http|socks]
  nix-proxy on [PORT] [http|socks]
  nix-proxy PORT [http|socks]
  nix-proxy off

PORT defaults to $PROXY_PORT, then to the configured default.
SCHEME defaults to $PROXY_SCHEME, then to "socks" (socks5h://...);
use "http" for HTTP-only listeners (e.g. `nix-proxy on 1080 http`).
The override is stored under /run and disappears on reboot.
`test` checks the local listener and outbound requests to the official
Nix cache and niri.cachix.org without changing nix-daemon.
USAGE
}

valid_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] && ((1 <= 10#$1 && 10#$1 <= 65535))
}

valid_scheme() {
  [[ "${1,,}" == http || "${1,,}" == socks ]]
}

daemon_env() {
  systemctl show nix-daemon --property=Environment --value 2>/dev/null || true
}

has_any_proxy() {
  grep -Eq '(^|[ "])(all_proxy|ALL_PROXY|http_proxy|HTTP_PROXY|https_proxy|HTTPS_PROXY|ftp_proxy|FTP_PROXY)=' <<<"$1"
}

has_expected_env() {
  local env="$1" url="$2" key

  for key in \
    http_proxy https_proxy ftp_proxy all_proxy \
    HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY; do
    grep -Fq "$key=$url" <<<"$env" || return 1
  done

  grep -Fq 'no_proxy=127.0.0.1,localhost,::1' <<<"$env" &&
    grep -Fq 'NO_PROXY=127.0.0.1,localhost,::1' <<<"$env"
}

has_proxy_url() {
  grep -Fq "ALL_PROXY=$2" <<<"$1"
}

listener_ready() {
  timeout 2 bash -c "exec 3<>\"/dev/tcp/\$1/\$2\"" nix-proxy-check "$PROXY_HOST" "$1"
}

show_status() {
  local state env
  state="$(systemctl is-active nix-daemon 2>/dev/null || true)"
  env="$(daemon_env)"
  [[ -n "$state" ]] || state="unknown"

  printf '    daemon service: %s\n' "$state"
  if has_any_proxy "$env"; then
    printf '\033[1;32m[+] nix-daemon unit environment: proxied\033[0m\n'
    grep -oE '(all_proxy|ALL_PROXY|http_proxy|HTTP_PROXY|https_proxy|HTTPS_PROXY|ftp_proxy|FTP_PROXY)=[^" ]+' <<<"$env" |
      sort -u |
      sed 's/^/    effective: /' || true
  else
    printf '\033[1;30m[-] nix-daemon unit environment: direct\033[0m\n'
  fi

  if [[ -f "$DROPIN" ]]; then
    printf '    transient override: %s\n' "$DROPIN"
  else
    printf '    transient override: absent\n'
  fi
}

resolve_port() {
  local explicit="${1:-}"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "$explicit"
  elif [[ -n "${PROXY_PORT:-}" ]]; then
    printf '%s\n' "$PROXY_PORT"
  else
    printf '%s\n' "$DEFAULT_PORT"
  fi
}

resolve_scheme() {
  local explicit="${1:-}"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "${explicit,,}"
  elif [[ -n "${PROXY_SCHEME:-}" ]]; then
    printf '%s\n' "${PROXY_SCHEME,,}"
  else
    printf 'socks\n'
  fi
}

scheme_url() {
  if [[ "$1" == http ]]; then
    printf 'http://%s:%s\n' "$PROXY_HOST" "$2"
  else
    printf 'socks5h://%s:%s\n' "$PROXY_HOST" "$2"
  fi
}

test_proxy() {
  local port="$1" scheme="$2" url test_url
  url="$(scheme_url "$scheme" "$port")"
  if ! listener_ready "$port"; then
    printf 'nix-proxy: no TCP listener at %s:%s\n' "$PROXY_HOST" "$port" >&2
    return 1
  fi
  printf 'nix-proxy: listener is reachable at %s:%s\n' "$PROXY_HOST" "$port"

  for test_url in "${TEST_URLS[@]}"; do
    if ! curl --fail --silent --show-error --location \
      --proxy "$url" \
      --connect-timeout 10 --max-time 20 \
      --output /dev/null \
      "$test_url"; then
      printf 'nix-proxy: %s is unreachable via %s\n' "$test_url" "$url" >&2
      return 1
    fi
    printf 'nix-proxy: %s OK via %s\n' "$test_url" "$url"
  done
}

rollback_activation() {
  local had_dropin="$1" changed="$2" reason="$3"

  if ((changed)); then
    if ((had_dropin)); then
      if ! sudo mv -f "$BACKUP" "$DROPIN"; then
        printf 'nix-proxy: %s; failed to restore the previous override\n' "$reason" >&2
        return 1
      fi
    elif ! sudo rm -f "$DROPIN" "$BACKUP"; then
      printf 'nix-proxy: %s; failed to remove the new override\n' "$reason" >&2
      return 1
    fi
  fi

  sudo rm -f "$PENDING"
  sudo rmdir --ignore-fail-on-non-empty "$DROPIN_DIR" 2>/dev/null || true
  if sudo systemctl daemon-reload && sudo systemctl restart nix-daemon; then
    printf 'nix-proxy: %s; previous proxy configuration was restored\n' "$reason" >&2
  else
    printf 'nix-proxy: %s; rollback failed, check nix-daemon\n' "$reason" >&2
  fi
  return 1
}

activate_proxy() {
  local port="$1" scheme="$2" url bypass desired env
  local had_dropin=0 changed=1

  if ! listener_ready "$port"; then
    printf 'nix-proxy: no TCP listener at %s:%s\n' "$PROXY_HOST" "$port" >&2
    return 1
  fi

  url="$(scheme_url "$scheme" "$port")"
  bypass="127.0.0.1,localhost,::1"
  desired="$(mktemp)" || return 1
  TEMP_FILE="$desired"

  cat >"$desired" <<EOF_DROPIN
[Service]
Environment="http_proxy=$url"
Environment="https_proxy=$url"
Environment="ftp_proxy=$url"
Environment="all_proxy=$url"
Environment="HTTP_PROXY=$url"
Environment="HTTPS_PROXY=$url"
Environment="FTP_PROXY=$url"
Environment="ALL_PROXY=$url"
Environment="no_proxy=$bypass"
Environment="NO_PROXY=$bypass"
EOF_DROPIN

  if ! sudo install -d -m 0755 "$DROPIN_DIR"; then
    printf 'nix-proxy: failed to create the transient drop-in directory\n' >&2
    return 1
  fi

  if sudo test -f "$DROPIN" && sudo cmp -s "$desired" "$DROPIN"; then
    changed=0
    sudo rm -f "$PENDING" "$BACKUP"
    env="$(daemon_env)"
    if systemctl is-active --quiet nix-daemon && has_expected_env "$env" "$url"; then
      printf '\033[1;32m[+] nix-daemon already uses %s\033[0m\n' "$url"
      return 0
    fi
  else
    if sudo test -f "$DROPIN"; then
      had_dropin=1
      if ! sudo cp -p "$DROPIN" "$BACKUP"; then
        printf 'nix-proxy: failed to preserve the previous override\n' >&2
        return 1
      fi
    else
      sudo rm -f "$BACKUP"
    fi

    if ! sudo install -m 0644 "$desired" "$PENDING" || ! sudo mv -f "$PENDING" "$DROPIN"; then
      sudo rm -f "$PENDING"
      if ((had_dropin)); then sudo rm -f "$BACKUP"; fi
      printf 'nix-proxy: failed to install the transient override\n' >&2
      return 1
    fi
  fi

  if ! sudo systemctl daemon-reload; then
    rollback_activation "$had_dropin" "$changed" "systemd reload failed"
    return 1
  fi
  if ! sudo systemctl restart nix-daemon; then
    rollback_activation "$had_dropin" "$changed" "nix-daemon restart failed"
    return 1
  fi

  env="$(daemon_env)"
  if ! systemctl is-active --quiet nix-daemon || ! has_expected_env "$env" "$url"; then
    rollback_activation "$had_dropin" "$changed" "effective proxy verification failed"
    return 1
  fi

  sudo rm -f "$PENDING" "$BACKUP"
  printf '\033[1;32m[+] nix-daemon proxied via %s\033[0m\n' "$url"
  printf '\033[1;30m    until reboot, or: nix_proxy off\033[0m\n'
}

deactivate_proxy() {
  local env

  if ! sudo test -f "$DROPIN"; then
    sudo rm -f "$PENDING" "$BACKUP"
    sudo rmdir --ignore-fail-on-non-empty "$DROPIN_DIR" 2>/dev/null || true
    env="$(daemon_env)"
    if systemctl is-active --quiet nix-daemon && ! has_any_proxy "$env"; then
      printf '\033[1;30m[-] nix-daemon is already direct; no restart needed\033[0m\n'
      return 0
    fi
    printf 'nix-proxy: its transient override is absent; daemon state was not changed\n' >&2
    show_status
    return 1
  fi

  if ! sudo cp -p "$DROPIN" "$BACKUP"; then
    printf 'nix-proxy: failed to preserve the active override\n' >&2
    return 1
  fi
  if ! sudo rm -f "$DROPIN" "$PENDING"; then
    sudo rm -f "$BACKUP"
    printf 'nix-proxy: failed to remove the transient override\n' >&2
    return 1
  fi

  if ! sudo systemctl daemon-reload || ! sudo systemctl restart nix-daemon; then
    if sudo mv -f "$BACKUP" "$DROPIN" &&
      sudo systemctl daemon-reload &&
      sudo systemctl restart nix-daemon; then
      printf 'nix-proxy: deactivation failed; previous proxy state was restored\n' >&2
    else
      printf 'nix-proxy: deactivation and rollback failed; check nix-daemon\n' >&2
    fi
    return 1
  fi

  sudo rm -f "$BACKUP"
  sudo rmdir --ignore-fail-on-non-empty "$DROPIN_DIR" 2>/dev/null || true
  env="$(daemon_env)"
  if has_any_proxy "$env"; then
    printf 'nix-proxy: its override was removed, but another unit override still sets a proxy\n' >&2
    show_status
    return 0
  fi
  printf '\033[1;31m[-] nix-daemon: direct\033[0m\n'
}

main() {
  local action="${1:-status}" port scheme

  case "$action" in
  status)
    (($# <= 1)) || {
      usage >&2
      return 2
    }
    show_status
    ;;
  test)
    (($# <= 3)) || {
      usage >&2
      return 2
    }
    port="$(resolve_port "${2:-}")"
    valid_port "$port" || {
      printf 'nix-proxy: invalid port: %s\n' "$port" >&2
      return 2
    }
    scheme="$(resolve_scheme "${3:-}")"
    valid_scheme "$scheme" || {
      printf 'nix-proxy: invalid scheme: %s (expected http or socks)\n' "$scheme" >&2
      return 2
    }
    test_proxy "$port" "$scheme"
    ;;
  on)
    (($# <= 3)) || {
      usage >&2
      return 2
    }
    port="$(resolve_port "${2:-}")"
    valid_port "$port" || {
      printf 'nix-proxy: invalid port: %s\n' "$port" >&2
      return 2
    }
    scheme="$(resolve_scheme "${3:-}")"
    valid_scheme "$scheme" || {
      printf 'nix-proxy: invalid scheme: %s (expected http or socks)\n' "$scheme" >&2
      return 2
    }
    activate_proxy "$port" "$scheme"
    ;;
  off)
    (($# == 1)) || {
      usage >&2
      return 2
    }
    deactivate_proxy
    ;;
  help | -h | --help)
    usage
    ;;
  *)
    if (($# == 1)) && valid_port "$action"; then
      scheme="$(resolve_scheme "")"
      if ! valid_scheme "$scheme"; then
        printf 'nix-proxy: invalid PROXY_SCHEME: %s (expected http or socks)\n' "$scheme" >&2
        return 2
      fi
      activate_proxy "$action" "$scheme"
    elif (($# == 2)) && valid_port "$1" && valid_scheme "$2"; then
      activate_proxy "$1" "${2,,}"
    else
      printf 'nix-proxy: unknown action or invalid port: %s\n' "$action" >&2
      usage >&2
      return 2
    fi
    ;;
  esac
}

main "$@"
