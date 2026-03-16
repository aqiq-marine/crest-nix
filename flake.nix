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
    openmp = pkgs.mpi;
    toml-f = pkgs.toml-f;
    dftd4 = pkgs.dftd4;
    s-dftd3 = pkgs.simple-dftd3;

    mctc-lib = pkgs.stdenv.mkDerivation {
      pname = "mctc-lib";
      version = "0.3.1";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "mctc-lib";
        rev = "v0.3.1";
        sha256 = "sha256-AXjg/ZsitdDf9fNoGVmVal1iZ4/sxjJb7A9W4yye/rg=";
      };

      nativeBuildInputs = commonNative;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
      '';
    };

    mstore = pkgs.stdenv.mkDerivation {
      pname = "mstore";
      version = "0.3.0";
    
      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "mstore";
        rev = "v0.3.0";
        sha256 = "sha256-zfrxdrZ1Um52qTRNGJoqZNQuHhK3xM/mKfk0aBLrcjw=";
      };
    
      nativeBuildInputs = commonNative;

      buildInputs = [
        mctc-lib
      ];
    
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
      '';
    };

    multicharge = pkgs.stdenv.mkDerivation {
      pname = "multicharge";
      version = "0.3.0";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "multicharge";
        rev = "v0.3.0";
        sha256 = "sha256-W6IqCz9k6kdPxnIIA+eMCrFjf0ELTeK78VvZoyFcZxU=";
      };

      nativeBuildInputs = commonNative;

      buildInputs = [
        mctc-lib
        mstore
      ] ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
      ];

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
      '';
    };

    tblite = pkgs.tblite


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

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
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

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
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
