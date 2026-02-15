{ config, lib, pkgs, unstable, inputs, nix-flatpak,  ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # ==========================================
  # BOOT & KERNEL (ZFS SUPPORT)
  # ==========================================

  boot = {
    # Using LTS kernel for ZFS compatibility
    kernelPackages = pkgs.linuxPackages;

    # Required for ZFS root
    supportedFilesystems = [ "zfs" ];

    # ntsync: Optimization for Wine/Proton gaming synchronization
    kernelModules = [ "ntsync" ];

    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev"; # Required for UEFI
        efiSupport = true;
        useOSProber = true; # Detects Windows/Other Linux installs
      };
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };


  # ==========================================
  # ZFS MAINTENANCE
  # ==========================================
  services.zfs.autoScrub.enable = true; # Periodically check data integrity
  services.zfs.trim.enable = true;      # SSD life preservation

  # ==========================================
  # NETWORKING & LOCALE
  # ==========================================
  networking = {
    hostName = "FumOS-Niri";
    hostId = "06f7afd1";    # CRITICAL: Do not change this after ZFS install!
    networkmanager.enable = true;
    # firewall.enable = false; # Uncomment if troubleshooting connection issues
  };

  time.timeZone = "America/Asuncion";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [ "ja_JP.UTF-8/UTF-8" ]; # Japanese support
    # Set regional formats to Paraguay (Spanish)
    extraLocaleSettings = {
      LC_ADDRESS = "es_PY.UTF-8";
      LC_IDENTIFICATION = "es_PY.UTF-8";
      LC_MEASUREMENT = "es_PY.UTF-8";
      LC_MONETARY = "es_PY.UTF-8";
      LC_NAME = "es_PY.UTF-8";
      LC_NUMERIC = "es_PY.UTF-8";
      LC_PAPER = "es_PY.UTF-8";
      LC_TELEPHONE = "es_PY.UTF-8";
      LC_TIME = "es_PY.UTF-8";
    };
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      ipafont
      kochi-substitute
      liberation_ttf
      nerd-fonts.symbols-only
      nerd-fonts.ubuntu-mono
      nerd-fonts.ubuntu
      nerd-fonts.hack
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      
    ];
  };


  # ==========================================
  # HARDWARE & GRAPHICS
  # ==========================================

  #Nvidia GPU
  #hardware.graphics = {
  # enable = true;
  #  enable32Bit = true; # Required for Steam/Wine
  #  extraPackages = with pkgs; [
  #    nvidia-vaapi-driver
  #    unstable.lsfg-vk
  #    vaapiVdpau
  #    libvdpau-va-gl
  #  ];
  #};
  #services.xserver.videoDrivers = ["nvidia"];
  #hardware.nvidia = {
  #  modesetting.enable = true;
  #  powerManagement.enable = true;
  #  powerManagement.finegrained = true;
  #  open = true;
  #  nvidiaSettings = true;
  #  package = config.boot.kernelPackages.nvidiaPackages.stable;
  #};


  #AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam/Wine
    extraPackages = [
      pkgs.libva
      pkgs.libva-vdpau-driver
      pkgs.libvdpau-va-gl
      unstable.lsfg-vk
      pkgs.mesa.opencl
      pkgs.rocmPackages.clr.icd
      ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  #Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  #Power Profiles Daemon
  services.power-profiles-daemon.enable = true;

  # GPU Daemon (Overclocking/Fan control)
  services.lact.enable = true;

  # Gaming Optimizations
  # Expose NTSYNC to users for gaming performance
  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0644", GROUP="users"
  '';

  # ==========================================
  # NIRI and Ly
  # ==========================================
  services.displayManager.ly = {
    enable = true;
    # Ajustes opcionales (por defecto ya funciona bien)
    settings = {
      animation = "matrix"; # Efecto matrix de fondo (opcional)
      # hide_borders = true;  # Más limpio
    };
  };


  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
      gnome-keyring
    ];
    config.common = {
      "org.freedesktop.impl.portal.FileChooser" = "gnome";
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
  };

  # ==========================================
  # USERS & SECURITY
  # ==========================================
  users.users.fumo = {
    isNormalUser = true;
    description = "Fumo";
    shell = pkgs.zsh;
    # 'libvirtd' for VMs, 'networkmanager' for wifi
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    packages = with pkgs; [

    ];
  };

  # Nautilus / GVFS support
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  # Allow FUSE for Rclone mounts
  programs.fuse.userAllowOther = true;

  # ==========================================
  # AUDIO (PipeWire)
  # ==========================================
  services.printing.enable = true;
  security.rtkit.enable = true; # Realtime priority for audio

  services.pulseaudio.enable = false; # Disable PulseAudio in favor of PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ==========================================
  # VIRTUALIZATION
  # ==========================================
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true; # TPM support for Windows 11 VMs
      };
    };
    podman = {
      enable = true;
      dockerCompat = true; # Aliases docker -> podman
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  programs.virt-manager.enable = true;
  services.spice-vdagentd.enable = true; # Clipboard sharing with VMs

  # ==========================================
  # SYSTEM PACKAGES
  # ==========================================

  programs.firefox.enable = false;

  programs.zsh = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vaapi        # Optional: AMD VAAPI support
      obs-gstreamer    # Recommended for better GStreamer-based encoding
      obs-pipewire-audio-capture
      obs-vkcapture
    ];
  }; 

  environment.systemPackages = with pkgs; [

    # -- Niri --
    niri
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    xwayland-satellite
    kitty
    alacritty
    fuzzel
    nautilus
    gthumb

    # -- Core Tools --
    wget git gh micro unrar _7zz fuse fastfetch
    vim neovim tealdeer p7zip xarchiver libva-utils ffmpeg

    # -- Gaming --
    mangohud goverlay lact vulkan-tools
    unstable.lsfg-vk-ui

    # -- Virtualization & Network --
    podman-compose rclone

    # -- Development --
    unstable.google-chrome
    unstable.antigravity-fhs
    unstable.vscodium-fhs

    # -- Productivity & Media --
    handbrake onlyoffice-desktopeditors
    qbittorrent thunderbird
    librewolf mpv audacious resources



  ];

  # ==========================================
  # GAMING SPECIFIC
  # ==========================================
  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  services.flatpak.enable = true;

  # Dynamically linked executables
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [

  ];

  # ==========================================
  # CUSTOM SERVICES
  # ==========================================
  




  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";

}
