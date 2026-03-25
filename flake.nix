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
    stdenv = pkgs.gcc13Stdenv;

    commonNative = with pkgs; [ cmake gfortran13 ];
    gfortran = pkgs.gfortran13;

    linalg = with pkgs; [ openblas lapack ];
    openmp = pkgs.mpi;
    toml-f = stdenv.mkDerivation rec {
      pname = "toml-f";
      version = "0.4.2";

      src = pkgs.fetchFromGitHub {
        owner = "toml-f";
        repo = "toml-f";
        rev = "v${version}";
        # sha256 = "sha256-QRghnzsLGuQ5MHoVVTDg6ACtwVIkIRexNx/zrrQ0Icc=";
        # 0.2.4
        # sha256 = "sha256-gt9phDu+1NIZ2tOTopf0NSYpwXUaRYHDcPnBEdy1jns=";
        # 0.3.0
        # sha256 = "sha256-zrmY+nyZ+jEWmhGL1adsMMzg6tbdj0orcns1AIIpf7w=";
        # 0.3.1
        # sha256 = "sha256-8FbnUkeJUP4fiuJCroAVDo6U2M7ZkFLpG2OYrapMYtU=";
        # 0.4.2
        sha256 = "sha256-+cac4rUNpd2w3yBdH1XoCKdJ9IgOHZioZg8AhzGY0FE=";
        # sha256 = pkgs.lib.fakeSha256;
      };

      nativeBuildInputs = [
        gfortran
        pkgs.pkg-config
        pkgs.meson
        pkgs.ninja
      ];

      buildInputs = [
        pkgs.test-drive
      ];

      buildPhase = ''
        ninja -j1
      '';
    };
    dftd4 = pkgs.dftd4;
    s-dftd3 = stdenv.mkDerivation rec {
      pname = "simple-dftd3";
      version = "0.6.0";

      src = pkgs.fetchFromGitHub {
        owner = "dftd3";
        repo = "simple-dftd3";
        tag = "v${version}";
        # hash = "sha256-c4xctcMcPQ70ippqbwtinygmnZ5en6ZGF5/v0ZWtzys=";
        # 0.6.0
        sha256 = "sha256-dvLePK6CaE2fd3GjRTBK5SSgf71DKNWh5dk+bw05NKU=";
        # sha256 = pkgs.lib.fakeSha256;
      };

      preInstall = ''
        echo "pre install"
        echo "print('hello nix python!')" | /usr/bin/env python
      '';
      postPatch = ''
        substituteInPlace config/install-mod.py \
          --replace "/usr/bin/env python" "${pkgs.python3}/bin/python3"
      '';

      nativeBuildInputs = [
        gfortran
        pkgs.pkg-config
        pkgs.meson
        pkgs.ninja
        pkgs.python3
      ] ++ commonNative;

      buildInputs = [
        mctc-lib
        mstore
        toml-f
      ] ++ linalg;
    };

    mctc-lib = stdenv.mkDerivation {
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

    mstore = stdenv.mkDerivation {
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

    multicharge = stdenv.mkDerivation {
      pname = "multicharge";
      version = "0.2.0";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "multicharge";
        rev = "v0.2.0";
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

    # tblite = oldpkgs.tblite;

    tblite = stdenv.mkDerivation rec {
      pname = "tblite";
      version = "0.3.0";

      src = pkgs.fetchFromGitHub {
        owner = "tblite";
        repo = "tblite";
        rev = "v${version}";
        # sha256 = "sha256-KV2fxB+SF4LilN/87YCvxUt4wsY4YyIV4tqnn+3/0oI=";
        # 0.3.0
        sha256 = "sha256-R7CAFG/x55k5Ieslxeq+DWq1wPip4cI+Yvn1cBbeVNs=";
        # sha256 = pkgs.lib.fakeSha256;
      };

      nativeBuildInputs = [
        gfortran
        pkgs.pkg-config
        pkgs.meson
        pkgs.ninja
      ];

      buildInputs = [
        mctc-lib
        mstore
        toml-f
        multicharge
        dftd4
        s-dftd3
      ] ++ linalg;

      buildPhase = ''
        ninja -j1
      '';
    };


    xtb = stdenv.mkDerivation {
      pname = "xtb";
      version = "6.7.1";

      src = pkgs.fetchFromGitHub {
        owner = "grimme-lab";
        repo = "xtb";
        rev = "v6.7.1";
        sha256 = "sha256-+qgXSMwzD0xSycZIRTokt77fZHHZQ++Npzr7NLlypOA=";
      };

      nativeBuildInputs = [
        pkgs.meson
        pkgs.ninja
        pkgs.pkg-config
        mctc-lib tblite multicharge
        dftd4
      ] ++ commonNative;

      buildInputs =
        [ mctc-lib tblite multicharge dftd4 pkgs.test-drive ]
        ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      ];
      mesonFlags = [
        "-Dcpcmx=disabled"
      ];

      buildPhase = ''
        ninja -j1
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp xtb $out/bin/
      '';

      postInstall = ''
        rm -f $out/lib/pkgconfig/*.pc
      '';
    };

    crest = stdenv.mkDerivation {
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
