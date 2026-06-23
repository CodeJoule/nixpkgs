{
  description = "Personal packages — patched forge, amphetamine-enhancer, Hermes patches";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
      patchSupergrok = ./patches/forge-supergrok.patch;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          forge = pkgs.callPackage ./packages/forge.nix { inherit patchSupergrok; };
          mlx-prism = pkgs.callPackage ./packages/mlx-prism.nix { };
        in
        {
          default = forge;
          inherit forge mlx-prism;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          amphetamine-enhancer = pkgs.callPackage ./packages/amphetamine-enhancer.nix { };
        });

      overlays.default = final: prev: {
        forge-supergrok = self.packages.${prev.system}.forge;
      };
    };
}