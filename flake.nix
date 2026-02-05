{
  description = "Niri on Nixos";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    noctalia = {
          url = "github:noctalia-dev/noctalia-shell";
          inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nix-flatpak, home-manager, ... }:
  let
    system = "x86_64-linux";
    # 1. Define unstable packages here
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.FumOS-Niri = nixpkgs.lib.nixosSystem {
      inherit system;
      # 2. This makes 'unstable' available to configuration.nix
      specialArgs = { inherit nix-flatpak; };
      specialArgs = { inherit inputs; };
      specialArgs = { inherit unstable; };
      modules = [
        ./configuration.nix
        #./noctalia.nix
        home-manager.nixosModules.home-manager
        nix-flatpak.nixosModules.nix-flatpak
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # 3. This makes 'unstable' and 'nix-flatpak' available to home.nix
            extraSpecialArgs = { inherit unstable nix-flatpak; };
            users.fumo = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
