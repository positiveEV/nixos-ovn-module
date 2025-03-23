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
    types
    literalExpression
    ;
  cfg = config.services.ovn-central;
in
{
  options.services.ovn-central = {
    enable = mkEnableOption "ovn central service";
    package = mkPackageOption pkgs "ovn" { };
    ovn_ctl_opts = mkOption {
      type = types.lines;
      default = "";
      example = "add example";
      description = "Extra options to pass to ovs-ctl";
    };
  };
  config = mkIf cfg.enable {
    systemd.services.ovn-central = {
      enable = true;
      description = "Open Virtual Network central components";
      after = [ "network.target" ];
      wants = [
        "ovn-northd.service"
        "ovn-nb-ovsdb.service"
        "ovn-sb-ovsdb.service"
      ];
      unitConfig = { };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/true";
        ExecStop = "/run/current-system/sw/bin/true";
        RemainAfterExit = "yes";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.ovn-northd = {
      enable = true;
      description = "Open Virtual Network central control daemon";
      after = [
        "network.target"
        "ovn-nb-ovsdb.service"
        "ovn-sb-ovsdb.service"
      ];
      partOf = [ "ovn-central.service" ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "forking";
        ExecStart = "${cfg.package}/share/ovn/scripts/ovn-ctl start_northd --ovn-manage-ovsdb=no --no-monitor ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/ovn/scripts/ovn-ctl stop_northd --no-monitor";
        Restart = "on-failure";
        LimitNOFILE = "65535";
        TimeoutStopSec = "15";
      };
    };

    systemd.services.ovn-nb-ovsdb = {
      enable = true;
      description = "Open vSwitch database server for OVN Northbound database";
      path = [ "/tmp" ];
      after = [ "network.target" ];
      partOf = [ "ovn-central.service" ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/share/ovn/scripts/ovn-ctl run_nb_ovsdb ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/ovn/scripts/ovn-ctl stop_nb_ovsdb";
        Restart = "on-failure";
        LimitNOFILE = "65535";
        TimeoutStopSec = "15";
      };
    };

    systemd.services.ovn-sb-ovsdb = {
      enable = true;
      description = "Open vSwitch database server for OVN Southbound database";
      path = [ "/tmp" ];
      after = [ "network.target" ];
      partOf = [ "ovn-central.service" ];
      unitConfig = {
        DefaultDependencies = "no";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/share/ovn/scripts/ovn-ctl run_sb_ovsdb ${cfg.ovn_ctl_opts}";
        ExecStop = "${cfg.package}/share/ovn/scripts/ovn-ctl stop_sb_ovsdb";
        Restart = "on-failure";
        LimitNOFILE = "65535";
        TimeoutStopSec = "15";
      };
    };
  };
}
