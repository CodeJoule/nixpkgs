{ lib
, stdenv
, fetchurl
, meson
, ninja
, pkg-config
, runCommand
, fuse-t
}:

let
  # fuse-t's .pc files hardcode /usr/local prefix — create a fixed version
  # as a proper derivation so Nix's pkg-config wrapper picks it up via buildInputs
  fuse-t-pc = runCommand "fuse-t-pkgconfig" { } ''
    mkdir -p $out/lib/pkgconfig
    for pc in ${fuse-t}/lib/fuse-t/pkgconfig/*.pc; do
      sed "s,prefix=/usr/local,prefix=${fuse-t}/lib/fuse-t,g" \
        "$pc" > "$out/lib/pkgconfig/$(basename $pc)"
    done
    # meson.build uses dependency('fuse'); fuse-t provides fuse3 — add alias
    cp $out/lib/pkgconfig/fuse3.pc $out/lib/pkgconfig/fuse.pc
    sed -i "s/Name: fuse3/Name: fuse/" $out/lib/pkgconfig/fuse.pc
  '';
in
stdenv.mkDerivation rec {
  pname = "9pfuse";
  version = "2";

  src = fetchurl {
    url = "https://github.com/aperezdc/9pfuse/releases/download/v${version}/9pfuse-${version}.tar.xz";
    sha256 = "0las6w0j7k8pb87dlkx2dyfbf1dd0h1xihkrrr86w4ms807gqwim";
  };

  nativeBuildInputs = [ meson ninja pkg-config fuse-t-pc ];
  buildInputs = [ fuse-t ];

  meta = with lib; {
    description = "Standalone FUSE-based 9P client from the Plan9 Port project";
    homepage = "https://github.com/aperezdc/9pfuse";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    maintainers = [ ];
  };
}
