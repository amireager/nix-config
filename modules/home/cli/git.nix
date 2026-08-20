{pkgs, ...}: let
  gitHostCheck = pkgs.writeShellApplication {
    name = "git-host-check";
    runtimeInputs = with pkgs; [coreutils findutils git nix];
    text = ''
      mode="''${GIT_CHECK_MODE:-$(git config --get checks.mode 2>/dev/null || printf 'auto')}"
      case "$mode" in
        off) exit 0 ;;
        auto | strict) ;;
        *)
          echo "git-host-check: checks.mode must be off, auto or strict" >&2
          exit 2
          ;;
      esac

      mapfile -d "" nix_files < <(git ls-files -co --exclude-standard -z -- '*.nix')
      mapfile -d "" shell_files < <(git ls-files -co --exclude-standard -z -- '*.sh')

      required=(git bash)
      if [ "''${#nix_files[@]}" -gt 0 ]; then
        required+=(nix-instantiate statix deadnix alejandra)
      fi

      missing=()
      for tool in "''${required[@]}"; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
      done

      if [ "''${#missing[@]}" -gt 0 ]; then
        printf 'git-host-check: missing host tools:' >&2
        printf ' %s' "''${missing[@]}" >&2
        printf '\n' >&2
        if [ "$mode" = strict ]; then
          echo "git-host-check: strict mode blocks push; activate the host configuration or use checks.mode=off" >&2
          exit 2
        fi
        echo "git-host-check: auto mode will run the available checks" >&2
      fi

      status=0
      git --no-pager diff --check || status=1
      git --no-pager diff --cached --check || status=1
      trailing="$(git grep -I -n -E '[[:blank:]]+$' -- . || true)"
      if [ -n "$trailing" ]; then
        printf '%s\n' "$trailing" >&2
        status=1
      fi

      if [ "''${#nix_files[@]}" -gt 0 ]; then
        if command -v nix-instantiate >/dev/null 2>&1; then
          for file in "''${nix_files[@]}"; do
            nix-instantiate --parse "$file" >/dev/null || status=1
          done
        fi

        if command -v statix >/dev/null 2>&1; then
          statix_output="$(mktemp)"
          if ! statix check . >"$statix_output" 2>&1; then
            cat "$statix_output" >&2
            status=1
          elif [ -s "$statix_output" ]; then
            cat "$statix_output" >&2
            status=1
          fi
          rm -f -- "$statix_output"
        fi

        if command -v deadnix >/dev/null 2>&1; then
          deadnix --fail . || status=1
        fi

        if command -v alejandra >/dev/null 2>&1; then
          alejandra --check . || status=1
        fi
      fi

      for file in "''${shell_files[@]}"; do
        bash -n "$file" || status=1
      done

      if [ "$status" -ne 0 ]; then
        if [ "$mode" = strict ]; then
          echo "git-host-check: checks failed; push blocked by strict mode" >&2
          exit "$status"
        fi
        echo "git-host-check: checks failed; auto mode allows the operation" >&2
        exit 0
      fi
      echo "git-host-check: available checks passed ($mode mode)"
    '';
  };

  postUpdate = pkgs.writeShellApplication {
    name = "git-post-update-check";
    runtimeInputs = [gitHostCheck];
    text = ''
      if ! git-host-check; then
        echo "git: update completed, but local checks failed; the next verified push will be blocked" >&2
      fi
      exit 0
    '';
  };

  gitHooks = pkgs.runCommand "host-git-hooks" {} ''
    mkdir -p "$out"
    ln -s ${gitHostCheck}/bin/git-host-check "$out/pre-push"
    ln -s ${postUpdate}/bin/git-post-update-check "$out/post-merge"
    ln -s ${postUpdate}/bin/git-post-update-check "$out/post-rewrite"
  '';
in {
  home.packages = [gitHostCheck];

  programs = {
    git = {
      enable = true;

      ignores = [
        ".direnv/"
        "result"
        "*.swp"
        ".DS_Store"
        ".idea/"
        ".vscode/"
        ".env.local"
        "*.log"
        "node_modules/"
        ".cache/"
        ".npm/"
        ".yarn/"
      ];

      settings = {
        user = {
          name = "amireager";
          email = "292326621+amireager@users.noreply.github.com";
        };

        # Core settings
        init.defaultBranch = "main";
        core.quotePath = false; # Show UTF-8 filenames (e.g. Persian) literally instead of \NNN escapes
        core.hooksPath = "${gitHooks}";

        # Strict on this host; any repository can override it locally.
        checks.mode = "strict";

        # Workflow
        pull.rebase = true;
        rebase.autoStash = true;
        rerere.enabled = true;
        fetch.prune = true;
        commit.verbose = true;

        # Diff & Merge
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        merge.conflictStyle = "zdiff3";
        merge.tool = "nvimdiff";

        # UI & Behavior
        column.ui = "auto";
        branch.sort = "-committerdate";
        tag.sort = "version:refname";

        # Push & Fetch
        push = {
          autoSetupRemote = true;
          followTags = true;
        };

        # Aliases — a practical everyday set
        alias = {
          # Status & Info
          st = "status -sb";
          br = "branch --sort=-committerdate";
          check = "!git-host-check";
          checks-off = "!git config --local checks.mode off";
          checks-auto = "!git config --local checks.mode auto";
          checks-strict = "!git config --local checks.mode strict";

          # Logging
          lg = "log --oneline --graph --decorate --all";
          lga = "log --oneline --graph --decorate --all -20";
          last = "log -1 HEAD --stat";
          who = "shortlog -s -n --all";

          # Commit
          c = "commit";
          ca = "commit --amend";
          cam = "commit --amend --no-edit";
          fix = "commit --fixup";

          # Staging
          a = "add";
          aa = "add --all";
          unstage = "restore --staged";

          # Branch & Switch
          co = "checkout";
          cob = "checkout -b";
          s = "switch";
          sw = "switch";
          main = "switch main";

          # Diff
          d = "diff";
          ds = "diff --staged";
          dc = "diff --cached";

          # Rebase & Merge
          ri = "rebase -i";
          ria = "rebase --abort";
          ric = "rebase --continue";

          # Remote
          p = "push";
          pl = "pull";
          f = "fetch --all --prune";
        };
      };
    };

    # Delta - Professional diff viewer
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = false;
        syntax-theme = "ansi";
        features = "decorations hyperlinks";
        decorations = {
          commit-decoration-style = "bold blue box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
      };
    };

    # GitHub CLI
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        aliases = {
          co = "pr checkout";
          pv = "pr view";
        };
      };
    };
  };
}
