{
  description = ";)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sf-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sf-fonts,
      nix4vscode,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit sf-fonts nix4vscode;
        };
        modules = [
          ./configuration.nix
        ];
      };
    };
}
