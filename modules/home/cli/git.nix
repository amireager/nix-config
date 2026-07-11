{...}: {
  programs.git = {
    enable = true;
    ignores = [
      ".direnv/"
      "result"
      "*.swp"
      ".DS_Store"
      ".idea/"
      ".vscode/"
    ];
    settings = {
      user = {
        name = "amireager";
        email = "292326621+amireager@users.noreply.github.com";
      };

      alias = {
        st = "status -sb";
        lg = "log --oneline --graph --decorate --all";
        last = "log -1 HEAD --stat";
        unstage = "reset HEAD --";
        amend = "commit --amend --no-edit";
      };

      init.defaultBranch = "main";

      pull.rebase = true;
      rebase.autoStash = true;
      rerere.enabled = true;

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      fetch.prune = true;

      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "ansi";
    };
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
