{
  description = "CREST + xTB (fully vendored)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs { inherit system; };

    commonNative = with pkgs; [ cmake gfortran ];
    linalg = with pkgs; [ openblas lapack ];

    mctc-lib = pkgs.stdenv.mkDerivation {
      pname = "mctc-lib";
      version = "0.3.1";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "mctc-lib";
        rev = "v0.3.1";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      };

      nativeBuildInputs = commonNative;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];
    };

    multicharge = pkgs.stdenv.mkDerivation {
      pname = "multicharge";
      version = "0.3.0";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "multicharge";
        rev = "v0.3.0";
        sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
      };

      nativeBuildInputs = commonNative;

      buildInputs = [ mctc-lib ];

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];
    };

    tblite = pkgs.stdenv.mkDerivation {
      pname = "tblite";
      version = "0.3.0";

      src = pkgs.fetchFromGitHub {
        owner = "tblite";
        repo = "tblite";
        rev = "v0.3.0";
        sha256 = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";
      };

      nativeBuildInputs = commonNative;

      buildInputs = [
        mctc-lib
        multicharge
      ] ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];
    };

    xtb = pkgs.stdenv.mkDerivation {
      pname = "xtb";
      version = "6.7.1";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "xtb";
        rev = "v6.7.1";
        sha256 = "sha256-+qgXSMwzD0xSycZIRTokt77fZHHZQ++Npzr7NLlypOA=";
      };

      nativeBuildInputs = commonNative;

      buildInputs =
        [ mctc-lib tblite multicharge ]
        ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      ];

      installPhase = ''
        mkdir -p $out/bin
        cp xtb $out/bin/
      '';
    };

    crest = pkgs.stdenv.mkDerivation {
      pname = "crest";
      version = "3.0.2";

      src = pkgs.fetchFromGitHub {
        owner = "crest-lab";
        repo = "crest";
        rev = "v3.0.2";
        sha256 = "sha256-AVLCC5banxmBQX8tuN2zSQbM7wKwrymfXLT5MBQSpPY=";
      };

      nativeBuildInputs = commonNative;

      buildInputs =
        [ xtb ]
        ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      ];

      installPhase = ''
        mkdir -p $out/bin
        cp crest $out/bin/
      '';
    };

  in
  {
    packages = {
      inherit crest xtb tblite multicharge mctc-lib;
      default = crest;
    };

    devShells.default = pkgs.mkShell {
      packages = [
        crest
        xtb
      ];
    };
  });
}
