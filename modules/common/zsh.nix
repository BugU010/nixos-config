{ ... }:
{
  # ===== shell 别名 =====
  home.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    lt = "eza --tree";
    nv = "nvim";
    vim = "nvim";
    vi = "nvim";
  };

  # ===== zsh =====
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "aliases"
        "sudo"
        "docker"
        "docker-compose"
      ];
    };
    initExtra = ''
      eval "$(zoxide init zsh)"
    '';
  };

  # ===== zoxide（HM 写法：cmd，不是 flags）=====
  programs.zoxide = {
    enable = true;
    cmd = "cd";
    enableZshIntegration = true;
  };

  # ===== starship =====
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # ===== fzf =====
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
