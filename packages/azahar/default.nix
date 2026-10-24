# Azahar (Nintendo 3DS emulator), built from nixpkgs' azahar recipe.
#
# AUTO-UPDATED WEEKLY: a job bumps `version` and `hash` below to the latest
# upstream stable release (https://github.com/azahar-emu/azahar/releases).
# Only those two lines should change on a bump.
#
# KEEP the metal_util.mm include fix in postPatch. Without it the macOS build
# fails with: src/citra_qt/util/metal_util.mm: error: unknown type name 'WId'
{ azahar }:

let
  version = "2126.2";
  hash = "sha256-wgF7n2ju8rP5jphHAj+fTLjfdhSz1OVDBHGNKJFlP2E=";
in
azahar.overrideAttrs (old: {
  inherit version;
  # nixpkgs' src is tagged by the package version; only the hash needs replacing.
  src = old.src.overrideAttrs (_: { outputHash = hash; outputHashAlgo = null; });

  # WId fix: include Qt's full QtGui window-defs header (must be kept).
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/citra_qt/util/metal_util.mm \
      --replace-fail '#import <qwindowdefs.h>' $'#import <qwindowdefs.h>\n#include <QtGui/qwindowdefs.h>'
  '';
})
