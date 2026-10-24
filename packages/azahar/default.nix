# nixpkgs' azahar, plus a fix for the macOS build:
#   src/citra_qt/util/metal_util.mm: error: unknown type name 'WId'
# `#import <qwindowdefs.h>` does not resolve to Qt's header there, so pull it in
# through the full QtGui framework path.
{ azahar }:

azahar.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./metal-util-wid.patch ];
})
