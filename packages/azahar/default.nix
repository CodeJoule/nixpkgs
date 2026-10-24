# Azahar (Nintendo 3DS emulator), built from nixpkgs' azahar recipe.
#
# AUTO-UPDATED WEEKLY: a job bumps `version` and `hash` below to the latest
# upstream stable release (https://github.com/azahar-emu/azahar/releases).
# Only those two lines should change on a bump.
#
# KEEP the metal_util WId fix in postPatch. Without it the macOS build fails:
#   src/citra_qt/util/metal_util.mm: error: unknown type name 'WId'
# Cause: with nixpkgs' Qt, <qwindowdefs.h> resolves to a one-line
# `#include_next <QtGui/qwindowdefs.h>` forwarding stub, and Objective-C++
# `#import` marks that stub as already seen, so Qt's real header never loads.
# Fix: drop the Qt include and use std::uintptr_t (what WId/quintptr is) in
# both metal_util.h and metal_util.mm. If --replace-fail trips after a bump,
# upstream changed these lines: re-check whether the fix is still needed.
{ azahar }:

let
  version = "2126.2";
  hash = "sha256-wgF7n2ju8rP5jphHAj+fTLjfdhSz1OVDBHGNKJFlP2E=";
in
azahar.overrideAttrs (old: {
  inherit version;
  # nixpkgs' src is tagged by the package version; only the hash needs replacing.
  src = old.src.overrideAttrs (_: { outputHash = hash; outputHashAlgo = null; });

  # WId fix (must be kept; see header comment).
  postPatch = (old.postPatch or "") + ''
    substituteInPlace src/citra_qt/util/metal_util.h \
      --replace-fail '#import "qwindowdefs.h"' '#include <cstdint>' \
      --replace-fail 'CreateMetalLayer(WId window)' 'CreateMetalLayer(std::uintptr_t window)'
    substituteInPlace src/citra_qt/util/metal_util.mm \
      --replace-fail '#import <qwindowdefs.h>' '#include <cstdint>' \
      --replace-fail 'CreateMetalLayer(WId winId)' 'CreateMetalLayer(std::uintptr_t winId)'
  '';
})
