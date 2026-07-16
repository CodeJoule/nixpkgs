{
  description = "Personal packages — patched forge, grok (transparent_bg), amphetamine-enhancer, Hermes patches";

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
      patchGrokTransparentBg = ./patches/grok-transparent-bg.patch;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          forge = pkgs.callPackage ./packages/forge.nix { inherit patchSupergrok; };
          grok = pkgs.callPackage ./packages/grok.nix {
            patchTransparentBg = patchGrokTransparentBg;
          };
          mlx-prism = pkgs.callPackage ./packages/mlx-prism.nix { };
        in
        {
          default = forge;
          inherit forge grok mlx-prism;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          amphetamine-enhancer = pkgs.callPackage ./packages/amphetamine-enhancer.nix { };
        });

      overlays.default = final: prev: {
        forge-supergrok = self.packages.${prev.system}.forge;
        # Source-built grok with [ui].transparent_bg support (replaces prebuilt).
        grok = self.packages.${prev.system}.grok;
      };
    };
}