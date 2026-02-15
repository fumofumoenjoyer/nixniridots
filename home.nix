{ config, pkgs, nix-flatpak, unstable, lib, ... }:

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
      "it.mijorus.gearlever"
      "com.heroicgameslauncher.hgl"
      "org.kde.kdenlive"
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
      onCalendar = "daily";
    };
  };

  home.activation = {
    configureFlatpakLanguages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.flatpak}/bin/flatpak config --user --set languages "en;ja"
    '';
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

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "FumoFumoEnjoyer";
        email = "FumoFumoEnjoyer@fumofumo.dev";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "dpoggi";
      plugins = [ "git" "sudo" ];
    };

    initExtra = ''
      fastfetch
    '';
  };
}
