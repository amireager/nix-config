{pkgs, ...}: let
  # ============================================================
  # GIT HOOKS — the thin local layer
  # ============================================================
  # Division of labor with .github/workflows/ci.yml:
  #   hook (here): instant, dependency-free checks (git + bash only)
  #   CI:          everything needing tools or full evaluation
  # Bypass any hook once with the standard:  git commit/push --no-verify
  # ============================================================
  # pre-commit — whitespace on STAGED changes only (milliseconds)
  gitPreCommit = pkgs.writeShellApplication {
    name = "git-pre-commit";
    runtimeInputs = with pkgs; [git];
    text = ''
      if ! git --no-pager diff --cached --check; then
        printf 'pre-commit: whitespace errors in staged changes\n' >&2
        printf 'pre-commit: fix them, or bypass once with: git commit --no-verify\n' >&2
        exit 1
      fi
    '';
  };

  # pre-push — last gate before code leaves the machine
  gitPrePush = pkgs.writeShellApplication {
    name = "git-pre-push";
    runtimeInputs = with pkgs; [git bash];
    text = ''
      status=0

      # Shell syntax on every tracked (and untracked-but-not-ignored) *.sh
      while IFS= read -r -d "" f; do
        bash -n "$f" || {
          printf 'pre-push: bash -n failed: %s\n' "$f" >&2
          status=1
        }
      done < <(git ls-files -co --exclude-standard -z -- '*.sh')

      # Trailing whitespace across tracked text files
      trailing="$(git grep -I -n -E '[[:blank:]]+$' -- . || true)"
      if [ -n "$trailing" ]; then
        printf '%s\n' "$trailing" >&2
        status=1
      fi

      if [ "$status" -ne 0 ]; then
        printf 'pre-push: local checks failed — bypass once with: git push --no-verify\n' >&2
        exit "$status"
      fi
    '';
  };

  gitHooks = pkgs.runCommand "host-git-hooks" {} ''
    mkdir -p "$out"
    ln -s ${gitPreCommit}/bin/git-pre-commit "$out/pre-commit"
    ln -s ${gitPrePush}/bin/git-pre-push "$out/pre-push"
  '';
in {
  home.packages = [
    gitPreCommit
    gitPrePush
  ];

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
