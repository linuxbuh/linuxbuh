# Calculate append=skip

The ac_install_live event:
- package installation (not chroot*)
- package removal (not chroot)
- system setup
- system installation
- first boot


*The event will not be used while the system is being built or if the package
is being installed in builder mode.

Action: package configuration
env: install
