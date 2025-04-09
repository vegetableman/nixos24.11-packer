packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "version" {
  description = "version"
  type = string
  default = "1.0.0"
}

variable "iso_url" {
  description = "iso_url"
  type = string
  default = "https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-aarch64-linux.iso"
}

variable "iso_checksum" {
  description = "iso_checksum"
  type = string
  default = "sha256:b2347b00187da66015f879e7046b1a2ef7199148e5d4749624161ece82f8ebf7"
}

source "qemu" "nixos" {
  iso_url = var.iso_url
  iso_checksum = var.iso_checksum
  accelerator = "hvf"
  machine_type = "virt,highmem=on"
  disk_size = "20G"
  memory = 4096
  cpus = 4
  headless = true
  ssh_username = "nixos"
  ssh_private_key_file   = "./scripts/vagrant"
  # IMPORTANT:This is the time Packer waits BEFORE sending any boot commands
  # SSH failures if not set
  boot_wait              = "30s"
  ssh_handshake_attempts = 100
  ssh_timeout            = "15m"
  ssh_wait_timeout       = "15m"
  # http_directory is the directory containing the files to be served over HTTP
  http_directory       = "scripts"
  # both files are required for qemu to boot on macos
  firmware = "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
  qemu_binary = "/opt/homebrew/bin/qemu-system-aarch64"
  qemuargs = [
    ["-boot", "order=cd"],
    ["-monitor", "stdio"], 
    ["-cpu", "host"],
    # virtio-net-device is a virtual network device that is used to connect to the network
    # user.0 is the network device id
    ["-device", "virtio-net-device,netdev=user.0"],
    # Port forwarding rule
    ["-netdev", "user,id=user.0,hostfwd=tcp::{{.SSHHostPort}}-:22"]
  ]
   boot_command = [
    # This wait is specifically for ensuring the shell is ready for the SSH setup commands
    "mkdir -m 0700 .ssh<enter>",
    # Places the public key into the authorized_keys file
    "curl http://{{ .HTTPIP }}:{{ .HTTPPort }}/vagrant.pub > .ssh/authorized_keys<enter>",
    "sudo systemctl start sshd<enter>"
  ]
}

build {
  # Refers to the source block defined above
  sources = ["source.qemu.nixos"]

  provisioner "shell" {
    # {{ .Vars }}: Placeholder for environment variables Packer needs to pass
    # {{ .Path }}: Placeholder for where Packer copies your script to in the VM
    execute_command = "sudo su -c '{{ .Vars }} {{ .Path }}'"
    script          = "./scripts/install.sh"
    # Expect disconnect is true to avoid ssh timeout
    expect_disconnect = true
  }

  post-processor "vagrant" {
    output = "nixos-24.11-aarch64-${var.version}.box"
    # Keep input artifact is false to avoid keeping the image as well in the build directory
    # Note: Not adding it seems to have no effect.
    keep_input_artifact = false
  }
} 