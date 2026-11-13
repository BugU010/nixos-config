{ ... }:

{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true; # 打开终端时自动启动或附加到 Zellij 会话
    settings = {
      # 示例：基础 UI 设置
      theme = "default";
      mouse_mode = true;
      # 其他 config.kdl 选项可在此声明
    };
    # extraConfig = '' ... ''; # 如需原始 KDL 字符串可追加
  };
}
