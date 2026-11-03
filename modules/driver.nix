{ config, pkgs, ... }:

{
  boot.extraModprobeConfig = ''
    # 绿联 USB 麦克风：跳过 HID 控制接口初始化，避免超时断连
    options usbhid quirks=0x2b89:0xd830:0x2

    # 其他设备的 quirk 以后可以继续追加在这里
    # options usbhid quirks=...
  '';
}
