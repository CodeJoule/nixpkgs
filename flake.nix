{
  description = "Personal packages — patched forge, grok (transparent_bg + Vesper + Opt+Space voice), amphetamine-enhancer, Hermes patches";

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
      # Paused (not currently used — Homebrew's forgecode cask covers this
      # instead). Left wired below, commented, so re-enabling later is a
      # one-line uncomment; packages/forge.nix pin is kept up to date.
      # patchSupergrok = ./patches/forge-supergrok.patch;
      patchGrokTransparentBg = ./patches/grok-transparent-bg.patch;
      patchGrokVesperTheme = ./patches/grok-vesper-theme.patch;
      patchGrokVoiceOptSpace = ./patches/grok-voice-opt-space.patch;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          # forge = pkgs.callPackage ./packages/forge.nix { inherit patchSupergrok; };
          grok = pkgs.callPackage ./packages/grok.nix {
            patchTransparentBg = patchGrokTransparentBg;
            patchVesperTheme = patchGrokVesperTheme;
            patchVoiceOptSpace = patchGrokVoiceOptSpace;
          };
          mlx-prism = pkgs.callPackage ./packages/mlx-prism.nix { };
          moshi-hook = pkgs.callPackage ./packages/moshi-hook.nix { };
          warp-agent-cli = pkgs.callPackage ./packages/warp-agent-cli.nix { };
        in
        {
          default = grok;
          inherit grok mlx-prism moshi-hook warp-agent-cli;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
          amphetamine-enhancer = pkgs.callPackage ./packages/amphetamine-enhancer.nix { };
        });

      overlays.default = final: prev: {
        # forge-supergrok = self.packages.${prev.system}.forge;
        # Source-built grok with transparent_bg, Vesper, Opt+Space voice.
        grok = self.packages.${prev.system}.grok;
      };
    };
}
