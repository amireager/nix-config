_box_complete() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  local opts="-e --ephemeral --tmp --secure --dry-run -n --offline --no-net --net -P --proxy -g --gpu -s --share -S --share-rw -w --workdir --clear-env --env --env-pass --profile --profiles --path --status --mem --cpu --clean --inspect -h --help"
  mapfile -t COMPREPLY < <(compgen -W "$opts" -- "$cur")
}
complete -F _box_complete box
