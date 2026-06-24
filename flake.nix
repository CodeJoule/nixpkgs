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
          macfuse = pkgs.callPackage ./packages/macfuse.nix { };
          fuse-t = pkgs.callPackage ./packages/fuse-t.nix { };
          "9pfuse" = pkgs.callPackage ./packages/9pfuse.nix { fuse-t = self.packages.${system}.fuse-t; };
        });

      overlays.default = final: prev: {
        forge-supergrok = self.packages.${prev.system}.forge;
      };
    };
}