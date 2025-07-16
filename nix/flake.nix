{
  description = ";)";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sf-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sf-fonts,
      determinate,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit sf-fonts; };
        modules = [
          ./configuration.nix
          determinate.nixosModules.default
        ];
      };
    };
}
