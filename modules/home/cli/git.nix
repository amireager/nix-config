_: {
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
