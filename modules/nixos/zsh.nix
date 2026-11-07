{ lib, pkgs, ... }:

{
  # ===== 全局默认 Shell =====
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];
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
        ];
      };
      interactiveShellInit = lib.mkAfter ''
        # zoxide 初始化（手动后置，确保二进制已在 PATH 中）
          eval "$(zoxide init zsh)"
      '';
    };

    zoxide = {
      enable = true;
      flags = [ "--cmd cd" ];
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      fuzzyCompletion = true; # 启用模糊补全
      keybindings = false; # 启用 Ctrl+R / Ctrl+T 等快捷键
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
