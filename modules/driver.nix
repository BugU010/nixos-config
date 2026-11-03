{ config, pkgs, ... }:

{
  # 用 udev 规则在设备插入时自动解绑故障 HID 接口
  services.udev.extraRules = ''
    # 绿联 UGREEN MIC-CM564：解绑 HID 控制接口，避免 usbhid 超时断连
    ACTION=="add|bind", SUBSYSTEM=="usb", ATTRS{idVendor}=="2b89", ATTRS{idProduct}=="d830", \
      ENV{DEVTYPE}=="usb_interface", ATTR{bInterfaceNumber}=="03", \
      RUN+="/bin/sh -c 'echo -n %k > /sys/bus/usb/drivers/usbhid/unbind 2>/dev/null || true'"
  '';

  # 同时保留之前的 quirk 作为兜底
  boot.extraModprobeConfig = ''
    options usbhid quirks=0x2b89:0xd830:0x4
    options snd-usb-audio ignore_ctl_error=1
  '';

  boot.kernelParams = [ "usbcore.autosuspend=-1" ];
}
