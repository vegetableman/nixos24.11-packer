{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi = {
      # Allows the OS to modify boot configuration
      canTouchEfiVariables = true;
      # Mount point for the EFI partition
      efiSysMountPoint = "/boot";
    };
    timeout = 0;
  };

  # Modules for QEMU
  # PIIX is QEMU's default virtual storage controller
  boot.initrd.availableKernelModules = [ "ata_piix" ];
  # Included in case NVMe storage is used
  boot.initrd.kernelModules = [ "nvme" ];
} 