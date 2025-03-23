{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    literalExpression
    types
    ;
  cfg = config.services.ovn-host;
in
{
  options.services.ovn-host = {
    enable = mkEnableOption "ovn host service";
    package = mkPackageOption pkgs "ovn" { };
    ovn_ctl_opts = mkOption {
      type = types.lines;
      default = "";
      example = "add example";
      description = "Extra options to pass to ovs-ctl";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    boot.kernelModules = [
      "tun"
      "openvswitch"
    ];
    boot.extraModulePackages = [ cfg.package ];

    systemd.services.ovn-host = {
      enable = true;
      description = "Open Virtual Network host components";
      after = [ "network.target" ];
      requires = [ "network.target" ];
      wants = [ "ovn-controller.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/true";
        ExecStop = "/run/current-system/sw/bin/true";
        RemainAfterExit = "yes";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.ovn-controller = {
      enable = true;
      description = "Open Virtual Network host control daemon";
      path = [ pkgs.gawk ];
      requires = [ "openvswitch-switch.service" ];
      after = [
        "network.target"
        "openvswitch-switch.service"
      ];
      partOf = [ "ovn-host.service" ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.package}/share/ovn/scripts/ovn-ctl start_controller --ovn-manage-ovsdb=no --no-monitor ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/ovn/scripts/ovn-ctl stop_controller --no-monitor";
        Restart = "on-failure";
        LimitNOFILE = "65535";
        TimeoutStopSec = "15";
      };
    };
    systemd.services.openvswitch-switch = {
      enable = true;
      description = "Open vSwitch";
      after = [
        "ovsdb-server.service"
        "network-pre.target"
        "ovs-vswitchd.service"
      ];
      before = [ "network.target" ];
      partOf = [ "network.target" ];
      requires = [
        "ovsdb-server.service"
        "ovs-vswitchd.service"
      ];
      path = [ pkgs.gawk ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/true";
        ExecStop = "${cfg.package}/share/openvswitch/scripts/ovs-ctl  --no-ovsdb-server stop";
        ExecReload = "${cfg.package}share/openvswitch/scripts/ovs-systemd-reload";
        RemainAfterExit = "yes";
      };
    };
    systemd.services.ovs-vswitchd = {
      enable = true;
      description = "Open vSwitch Forwarding Unit";
      after = [
        "ovsdb-server.service"
        "network-pre.target"
        "systemd-udev-settle.service"
      ];
      before = [
        "network.target"
        "networking.service"
      ];
      partOf = [ "openvswitch-switch.service" ];
      path = [
        pkgs.gawk
        pkgs.kmod
      ];
      requires = [ "ovsdb-server.service" ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --no-monitor --system-id=random --no-record-hostname start ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/openvswitch/scripts/ovs-ctl  --no-ovsdb-server stop";
        Restart = "on-failure";
        ExecReload = "${cfg.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --no-monitor --system-id=random --no-record-hostname restart ${cfg.ovn_ctl_opts}";
        LimitNOFILE = "1048576";
        TimeoutSec = "300";
        OOMScoreAdjust = "900";
      };
    };
    systemd.services.ovsdb-server = {
      enable = true;
      description = "Open vSwitch Database Unit";
      after = [
        "systemd-journald.socket"
        "network-pre.target"
        "dpdk.service"
        "local-fs.target"
      ];
      before = [
        "network.target"
        "networking.service"
      ];
      partOf = [ "openvswitch-switch.service" ];
      path = [
        pkgs.gawk
        pkgs.util-linux
      ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd --no-monitor --system-id=random --no-record-hostname start ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd stop";
        Restart = "on-failure";
        ExecReload = "${cfg.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd --no-record-hostname --no-monitor restart ${cfg.ovn_ctl_opts}";
        LimitNOFILE = "1048576";
        TimeoutSec = "300";
        OOMScoreAdjust = "900";
        RuntimeDirectory = "openvswitch";
        RuntimeDirectoryMode = "0755";
        RuntimeDirectoryPreserve = "yes";
      };
    };
  };
}
