{ lib, ... }:

{
  programs = {
    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [
          "git"
          "aliases"
          "alias-finder"
          "cp"
          "copypath"
          "copyfile"
          "sudo"
          "docker"
          "docker-compose"
          "zoxide"
        ];
      };
    };

        zoxide = {
      enable = true;
      flags = [ "--cmd cd" ];
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      fuzzyCompletion = true;   # 启用模糊补全
      keybindings = false;       # 启用 Ctrl+R / Ctrl+T 等快捷键
    };


  }; 
  environment.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    lt = "eza --tree";
    nv = "nvim";
    vim = "nvim";
    vi = "nvim";
  };
}
