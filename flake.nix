{
  description = "Personal packages — amphetamine-enhancer, moshi-hook, warp-agent-cli";

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
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          moshi-hook = pkgs.callPackage ./packages/moshi-hook.nix { };
          warp-agent-cli = pkgs.callPackage ./packages/warp-agent-cli.nix { };
        in
        {
          inherit moshi-hook warp-agent-cli;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          amphetamine-enhancer = pkgs.callPackage ./packages/amphetamine-enhancer.nix { };
        }
        );
    };
}
