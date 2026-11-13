# hosts/darwin/macbook/default.nix
{ pkgs, ... }:
{
  # nix-darwin 的基础设置
  nix.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # 系统状态版本（根据你的 macOS 版本调整）
  system.stateVersion = 6;

  # 你的实际 macOS 配置从 /etc/nix-darwin/configuration.nix 迁移过来
  # services.nix-daemon.enable = true;
  # users.users.yourname = { ... };
  # homebrew.enable = true;
  # ...
}
