{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Great_Wall_GW3500_2TB_2026061700025";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              start = "1M";
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              priority = 2;
              size = "16G";
              content = {
                type = "swap";
              };
            };
            nix = {
              priority = 3;
              size = "512G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
                extraArgs = [ "-F" ];
                mountOptions = [ "noatime" ];
              };
            };
            root = {
              priority = 4;
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [ "-F" ];
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
