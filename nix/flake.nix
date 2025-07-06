{
  description = ";)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sf-fonts.url = "github:Lyndeno/apple-fonts.nix";
  };

  outputs = { self, nixpkgs, sf-fonts, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit sf-fonts; };
      modules = [
        ./configuration.nix
      ];
    };
  };
}
