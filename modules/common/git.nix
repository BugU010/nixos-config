{ ... }:

{
  programs.git = {
    enable = true;

    # 启用 Git LFS（自动安装 git-lfs 并配置相关钩子）
    lfs.enable = true;

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
