{ ... }:

{
  programs.git = {
    enable = true;

    config = {
      user = {
        name = "BugU010";
        email = "timing_wzy@163.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      credential.helper = "store";
    };
  };
}
