{ lib
, python314
, fetchFromGitHub
, cmake
, ninja
, apple-sdk
}:

let
  mlx-prism-py = python314.pkgs.buildPythonPackage {
    pname = "mlx-prism";
    version = "0-unstable-2026-06-18";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "PrismML-Eng";
      repo = "mlx";
      rev = "88c9c205a50fbaaf432a50338570d85273925601";
      hash = "sha256-shMMIbT+819kX0qpT8mzFmdNEIqx/19Zz5XTwMi4xhA=";
    };

    build-system = [
      python314.pkgs.setuptools
      python314.pkgs.cmake
      ninja
    ];

    nativeBuildInputs = [ cmake ninja ];

    buildInputs = [ apple-sdk ];

    doCheck = false;

    meta = {
      description = "PrismML fork of Apple MLX with 1-bit quantization kernel support";
      homepage = "https://github.com/PrismML-Eng/mlx";
      license = lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
    };
  };

  mlx-lm-prism = python314.pkgs.mlx-lm.override {
    mlx = mlx-prism-py;
  };

  pythonEnv = python314.withPackages (ps: [
    mlx-prism-py
    mlx-lm-prism
  ]);

in pythonEnv
