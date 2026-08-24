{ lib
, stdenv
, fetchFromGitHub
, zig
, makeBinaryWrapper
}:

# fx — Vercel's tiny native coding agent (https://fx.sh).
#
# A plain Zig build: build.zig.zon declares `.dependencies = .{}`, so there is
# no dependency tree to vendor and zig.hook alone is enough. Two upstream
# behaviours need handling for a /nix/store install:
#
#   1. The version string is read out of src/main.zig at build time, and
#      git_commit is read from `git rev-parse` — which is absent in the
#      fetchFromGitHub tarball. readGitCommit() already degrades to "unknown"
#      rather than failing, so only the version is asserted below.
#   2. Auto-upgrade downloads a new binary and swaps it over the running
#      executable. shouldEnableForCurrentExecutable() only opts out of
#      *development* builds (paths containing /zig-out/bin/), so a store path
#      is treated as upgradeable and the swap fails against a read-only store.
#      Upstream honours FX_AUTO_UPGRADE=0; the wrapper sets it unconditionally
#      (--set, not --set-default) since re-enabling it can only ever fail here.
#
# Note the binary conflicts with pkgs.fx, the unrelated terminal JSON viewer:
# both install bin/fx. Don't put them in the same profile.

stdenv.mkDerivation (finalAttrs: {
  pname = "fx-agent";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "fx";
    tag = "v${finalAttrs.version}";
    hash = "sha256-r7fSv4M+rI4kbWyIeW6JsHLQ+WRSaLYwkxkz/16eu7k=";
  };

  nativeBuildInputs = [
    zig.hook
    makeBinaryWrapper
  ];

  # Guard the version pin: build.zig parses this constant to stamp `fx
  # --version`, so a bump that misses it produces a binary that lies about
  # itself instead of failing.
  postPatch = ''
    grep -q 'pub const version = "${finalAttrs.version}"' src/main.zig \
      || (echo "fx-agent: src/main.zig version does not match ${finalAttrs.version}" >&2; exit 1)
  '';

  postInstall = ''
    wrapProgram "$out/bin/fx" --set FX_AUTO_UPGRADE 0
  '';

  # Cheap smoke test: proves the version got stamped and the wrapper execs.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/fx" --version | grep -q '${finalAttrs.version}'
    runHook postInstallCheck
  '';

  meta = {
    description = "Tiny, open, embeddable, native coding agent";
    longDescription = ''
      fx is a coding agent written in Zig that talks to models through the
      Vercel AI Gateway. It needs credentials before it will do anything —
      `fx` prompts for a gateway login on first run, storing the token in the
      macOS keychain via /usr/bin/security.

      Auto-upgrade is disabled in this build; bump packages/fx-agent.nix and
      rebuild instead.
    '';
    homepage = "https://fx.sh";
    downloadPage = "https://github.com/vercel-labs/fx/releases";
    changelog = "https://github.com/vercel-labs/fx/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "fx";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
})
