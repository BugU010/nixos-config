{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.snapper = {
    snapshotInterval = "*-*-* 00/2:00:00"; # 每 2 小时
    cleanupInterval = "1d";
    filters = "/nix";

    configs = {
      root = {
        SUBVOLUME = "/";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 0;
      };

      home = {
        SUBVOLUME = "/home";
        FSTYPE = "btrfs";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 12;
        TIMELINE_LIMIT_DAILY = 7;
        TIMELINE_LIMIT_WEEKLY = 4;
        TIMELINE_LIMIT_MONTHLY = 0;
      };
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # ── 启用 Btrfs dynamic reclaim ──
  systemd.services.btrfs-set-dynamic-reclaim = {
    description = "Enable dynamic reclaim on all btrfs data block groups";
    wantedBy = [ "multi-user.target" ];

    script = ''
      shopt -s failglob
      for root in /sys/fs/btrfs/*-*/allocation/data; do
        echo 1 > "$root/dynamic_reclaim"
        echo 1 > "$root/periodic_reclaim"
      done
    '';

    serviceConfig = {
      Type = "oneshot";
      PrivateNetwork = true;
      ProtectHome = true;
      ProtectSystem = true;
      ReadWritePaths = [ "/sys/fs/btrfs" ];
    };
  };

  # ── Btrfs Unallocated 告警检查 ──
  systemd.services.btrfs-unallocated-check = {
    description = "Check Btrfs unallocated space and push alert via ntfy";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/btrfs-unallocated-alert.sh";
      Environment = [
        "PATH=${pkgs.coreutils}/bin:${pkgs.btrfs-progs}/bin:${pkgs.curl}/bin:${pkgs.gawk}/bin:${pkgs.util-linux}/bin"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

  systemd.timers.btrfs-unallocated-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

}
