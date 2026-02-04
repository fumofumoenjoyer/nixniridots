{ config, pkgs, nix-flatpak, ... }:

{
  imports = [
    nix-flatpak.homeManagerModules.nix-flatpak
  ];


  home.username = "fumo";
  home.homeDirectory = "/home/fumo";
  home.stateVersion = "25.11";
  home.packages = with pkgs; [
    brave
  ];
  
  # ==========================================
  # FLATPAK
  # ==========================================
  services.flatpak = {
    enable = true;
    update.onActivation = true;

    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];

    packages = [
      "com.discordapp.Discord"
      "io.github.flattool.Warehouse"
      "org.prismlauncher.PrismLauncher"
      "org.torproject.torbrowser-launcher"
      "com.discordapp.Discord"
      "com.github.Matoking.protontricks"
      "com.github.tchx84.Flatseal"
      "com.protonvpn.www"
      "com.stremio.Stremio"
      "com.usebottles.bottles"
      "com.vysp3r.ProtonPlus"
      "net.retrodeck.retrodeck"
      "org.vinegarhq.Sober"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };

  # ==========================================
  # CONFIG
  # ==========================================
  xdg.configFile = {
    "niri".source = config.lib.file.mkOutOfStoreSymlink /home/fumo/nixniridots/.config/niri;
    "noctalia".source = config.lib.file.mkOutOfStoreSymlink /home/fumo/nixniridots/.config/noctalia;
    "kitty".source = config.lib.file.mkOutOfStoreSymlink /home/fumo/nixniridots/.config/kitty;
    "fastfetch".source = config.lib.file.mkOutOfStoreSymlink /home/fumo/nixniridots/.config/fastfetch;
  };

  home.file."Pictures/Wallpapers".source = config.lib.file.mkOutOfStoreSymlink /home/fumo/nixniridots/wallpapers;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "FumoFumoEnjoyer";
        email = "FumoFumoEnjoyer@fumofumo.dev";
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
    };
    profileExtra = ''

    '';
  };
}
