{
  description = "CREST 3.0.2 built with its upstream-pinned subprojects";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        crest = pkgs.stdenv.mkDerivation {
          pname = "crest";
          version = "3.0.2";

          # Keep the exact subproject revisions recorded by the upstream
          # v3.0.2 gitlinks. Do not independently update Fortran dependencies.
          src = pkgs.fetchFromGitHub {
            owner = "crest-lab";
            repo = "crest";
            rev = "v3.0.2";
            fetchSubmodules = true;
            hash = "sha256-YCqUwQc8Cr58YKxromGEnMp/MRmAe8NhNr6Lo2783Pk=";
          };

          nativeBuildInputs = [
            pkgs.cmake
            pkgs.ninja
            pkgs.gfortran14
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.openblas
            pkgs.mctc-lib.dev
          ];

          cmakeBuildType = "Release";

          cmakeFlags = [
            "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
            "-DWITH_TESTS=OFF"
            "-DWITH_OpenMP=ON"
            "-DWITH_TBLITE=ON"
            "-DWITH_TOMLF=ON"
            "-DWITH_GFN0=ON"
            "-DWITH_GFNFF=ON"
            "-DWITH_LWONIOM=ON"
          ];

          doCheck = false;

          meta = {
            description = "Conformer-Rotamer Ensemble Sampling Tool";
            homepage = "https://github.com/crest-lab/crest";
            license = pkgs.lib.licenses.lgpl3Plus;
            platforms = pkgs.lib.platforms.linux;
            mainProgram = "crest";
          };
        };
      in
      {
        packages = {
          inherit crest;
          default = crest;
        };

        devShells.default = pkgs.mkShell {
          packages = [ crest ];
        };
      });
}
