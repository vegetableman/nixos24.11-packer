{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./hardware-builder.nix
  ];

  # Cleans up temporary files on boot
  boot.tmp.cleanOnBoot = true;

  # ZRAM-based swap - better performance than disk swap.
  # Provides better performance than traditional swap
  zramSwap.enable = true;

  services.openssh = {
    enable = true;
    # This is a recommended security practice for Vagrant boxes since 
    # they should only use SSH key authentication and never need 
    # interactive password prompts.
    settings.KbdInteractiveAuthentication = false;

    # This works for both RSA and ed25519 keys
    extraConfig = "PubkeyAcceptedAlgorithms=+ssh-rsa";
    
    # Disables reverse DNS lookups during SSH connections.
    # Avoid potential delays when DNS is unavailable
    settings.UseDns = false;
  };

  users.users.root = { 
    initialPassword = "vagrant";  
  };
  
  # Creates a "vagrant" group & user with password-less sudo access
  users.groups.vagrant = {
    name = "vagrant";
    members = [ "vagrant" ];
  };
  users.users.vagrant = {
    name = "vagrant";
    group = "vagrant";
    extraGroups = [ "users" "wheel" ];
    password = "vagrant";
    home = "/home/vagrant";
    description = "Vagrant on aarch64 NixOS";
    isNormalUser = true;
    createHome = true;
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"  
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1YdxBpNlzxDqfJyw/QKow1F+wvG9hXGoqiysfJOn5Y vagrant insecure public key"
    ];
  };

  # Lines 1-3 - These lines preserve specific environment variables when using sudo
  # Line 4 - Preserves SSH agent connection when using sudo
  # Line 5 - Turns off the default sudo usage warning message
  # Line 6 - Permissions
  security.sudo.extraConfig =
    ''
      Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
      Defaults:root,%wheel env_keep+=NIX_PATH
      Defaults:root,%wheel env_keep+=TERMINFO_DIRS
      Defaults env_keep+=SSH_AUTH_SOCK
      Defaults lecture = never
      root   ALL=(ALL) SETENV: ALL
      %wheel ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
    '';

  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "24.11";
} 