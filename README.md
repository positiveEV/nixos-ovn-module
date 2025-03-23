# NixOS OVN Module

This module generates systemd service files for OVN and the OVS services needed by OVN. The systemd service files are heavily based on those provided by the Debian package ([Debian source for OVN])(https://sources.debian.org/src/ovn).

## Using this module

You can simply copy the three `.nix` files into the same directory as your `configuration.nix` and then import `./ovn.nix` in your `configuration.nix`.
`ovn.nix` imports `ovn-host.nix` and `ovn-central.nix`, and activates their services using the `services.ovn-*.enable` options.
You can also modify `ovn.nix` to pass options to these services by setting `services.ovn-*.ovn_ctl_opts`, as you would have on Debian by setting the `OVN_CTL_OPTS` environment variable in `/etc/default/ovn-*`

## Using OVN with Incus

You need to change the `network.ovs.connection` server configuration option in Incus for it to find the OVS database.
If you did not set `services.ovn-*.ovn_ctl_opts`, you will have a standalone OVN installation with an OVS server listening at `/usr/local/var/run/openvswitch/db.sock`, therefore you need to set the option as follows:

```
network.ovs.connection: unix:/usr/local/var/run/openvswitch/db.sock
```

## Known Issues

* At shutdown incus stop command timeouts after 10 minutes.
