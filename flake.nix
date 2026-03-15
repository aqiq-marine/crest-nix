{
  description = "CREST + xTB build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        xtb = pkgs.stdenv.mkDerivation {
          pname = "xtb";
          version = "6.7";

          src = pkgs.fetchFromGitHub {
            owner = "grimme-lab";
            repo = "xtb";
            rev = "v6.7.1";
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.gfortran
          ];

          buildInputs = [
            pkgs.openblas
            pkgs.lapack
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp build/xtb $out/bin/
          '';
        };

        crest = pkgs.stdenv.mkDerivation {
          pname = "crest";
          version = "3.0.2";

          src = pkgs.fetchFromGitHub {
            owner = "crest-lab";
            repo = "crest";
            rev = "v3.0.2";
            sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
          };

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.gfortran
          ];

          buildInputs = [
            pkgs.openblas
            pkgs.lapack
            xtb
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp _build/crest $out/bin/
          '';
        };

      in
      {
        packages.default = crest;

        packages = {
          inherit crest xtb;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            crest
            xtb
          ];
        };
      });
}
