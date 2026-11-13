{
  description = "CREST + xTB (fully source-built stack)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d4f25a3e562008648d45bcf2d70bcc7422cad84e";
    flake-utils.url = "github:numtide/flake-utils/cd489559845d81f673a12885576016c65cbe9363";
  };

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    stdenv = pkgs.stdenv;

    commonNative = with pkgs; [ cmake gfortran pkg-config meson ninja ];
    linalg = with pkgs; [ openblas lapack ];
    testDriveSrc = pkgs.test-drive.src;

    gfn0Src = pkgs.fetchFromGitHub {
      owner = "pprcht";
      repo = "gfn0";
      rev = "main";
      sha256 = "sha256-84hBN9uaEoOEu7OEve8CoLOBoHc1XR02pYfBY5cJFXU=";
    };

    gfnffSrc = pkgs.fetchFromGitHub {
      owner = "pprcht";
      repo = "gfnff";
      rev = "42963235cba66f81575f17b2dba8be7acf2a440d";
      sha256 = "sha256-Og/RL33Jz9okweq18NIKNsOYay+BF9qZHv9zlELMozI=";
    };

    lwoniomSrc = pkgs.fetchFromGitHub {
      owner = "crest-lab";
      repo = "lwoniom";
      rev = "main";
      sha256 = "sha256-33cKyUYnG3KJ54oAh2zOv6frRN/i2XKeVDpEdISlncE=";
    };

    # Match the tblite submodule pinned by CREST v3.0.2.
    tbliteSrc = pkgs.fetchFromGitHub {
      owner = "pprcht";
      repo = "tblite";
      rev = "4556e28f391573b3c80c94beb7c56313005d5269";
      sha256 = "sha256-JmTEnvYqA73vmWQe4cpjvp6/Wwb+elSMDdHTPwD3/jc=";
    };

    toml-f = stdenv.mkDerivation {
      pname = "toml-f";
      version = "0.5.1";
      src = pkgs.toml-f.src;
      nativeBuildInputs = commonNative;
      postPatch = ''
        substituteInPlace meson.build --replace "subdir('test')" "" || true
      '';
      dontFixup = true;
    };

    mctc-lib = stdenv.mkDerivation {
      pname = "mctc-lib";
      version = "0.5.1";
      src = pkgs.mctc-lib.src;
      nativeBuildInputs = commonNative;
      cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" "-DWITH_OpenMP=OFF" ];
      dontFixup = true;
    };

    mstore = stdenv.mkDerivation {
      pname = "mstore";
      version = "0.4.0";
      src = pkgs.mstore.src;
      nativeBuildInputs = commonNative;
      buildInputs = [ mctc-lib ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
      ];
      dontFixup = true;
    };

    multicharge = stdenv.mkDerivation {
      pname = "multicharge";
      version = "0.5.0";
      src = pkgs.multicharge.src;
      nativeBuildInputs = commonNative;
      buildInputs = [ mctc-lib mstore ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
      ];
      dontFixup = true;
    };

    simple-dftd3 = stdenv.mkDerivation {
      pname = "simple-dftd3";
      version = "0.6.0";
      src = pkgs.simple-dftd3.src;
      nativeBuildInputs = commonNative ++ [ pkgs.python3 ];
      buildInputs = [ mctc-lib mstore toml-f ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
      ];
      dontFixup = true;
    };

    # tblite 0.3.0 and DFT-D4 3.4.0 use the older multicharge API.
    # Keep that package version pinned, but share the current mctc-lib,
    # mstore and toml-f targets with the rest of the build to avoid duplicate
    # Fortran module namespaces in CREST.
    legacyMultichargeSrc = pkgs.fetchFromGitHub {
      owner = "grimme-lab";
      repo = "multicharge";
      rev = "v0.2.0";
      sha256 = "sha256-oUI5x5/Gd0EZBb1w+0jlJUF9X51FnkHFu8H7KctqXl0=";
    };

    legacySimpleDftd3Src = pkgs.fetchFromGitHub {
      owner = "dftd3";
      repo = "simple-dftd3";
      rev = "v0.7.0";
      sha256 = "sha256-5OvmMgjD8ujjKHkuw4NT8hEXKh5YPxuBl/Mu6g2/KIA=";
    };

    legacyMulticharge = stdenv.mkDerivation {
      pname = "multicharge";
      version = "0.2.0";
      src = legacyMultichargeSrc;
      nativeBuildInputs = commonNative;
      buildInputs = [ mctc-lib mstore ] ++ linalg;
      postPatch = ''
        substituteInPlace CMakeLists.txt --replace 'add_subdirectory("test")' "" || true
      '';
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
      ];
      dontFixup = true;
    };

    legacySimpleDftd3 = stdenv.mkDerivation {
      pname = "simple-dftd3";
      version = "0.7.0";
      src = legacySimpleDftd3Src;
      nativeBuildInputs = commonNative ++ [ pkgs.python3 ];
      buildInputs = [ mctc-lib mstore toml-f ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DWITH_TESTS=OFF"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
      ];
      dontFixup = true;
    };

    dftd4Src = pkgs.fetchFromGitHub {
      owner = "dftd4";
      repo = "dftd4";
      rev = "v3.4.0";
      sha256 = "sha256-YJ4btnKQVeaE/zwatBR/OEH5qdiQOTqAFga1CRz+EWQ=";
    };

    dftd4 = stdenv.mkDerivation {
      pname = "dftd4";
      version = "3.4.0";
      src = dftd4Src;
      nativeBuildInputs = commonNative;
      buildInputs = [ mctc-lib mstore legacyMulticharge toml-f ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Dmulticharge_DIR=${legacyMulticharge}/lib/cmake/multicharge"
      ];
      dontFixup = true;
    };

    tblite = stdenv.mkDerivation {
      pname = "tblite";
      version = "0.3.0";
      src = tbliteSrc;
      nativeBuildInputs = commonNative;
      buildInputs = [ mctc-lib mstore toml-f legacyMulticharge dftd4 legacySimpleDftd3 ] ++ linalg;
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Ds-dftd3_DIR=${legacySimpleDftd3}/lib/cmake/s-dftd3"
        "-Ddftd4_DIR=${dftd4}/lib/cmake/dftd4"
      ];
      dontFixup = true;
    };

    xtb = stdenv.mkDerivation {
      pname = "xtb";
      version = "6.7.1";
      src = pkgs.xtb;
      phases = [ "installPhase" ];
      installPhase = ''
        mkdir -p $out/lib/cmake/xtb $out/bin $out/include $out/lib
        ln -s ${pkgs.xtb}/bin/* $out/bin/
        ln -s ${pkgs.xtb}/include/* $out/include/
        ln -s ${pkgs.xtb}/lib/* $out/lib/

        cat << 'EOF' > $out/lib/cmake/xtb/xtbConfig.cmake
        set(xtb_FOUND TRUE)
        add_library(xtb::xtb SHARED IMPORTED)
        set_target_properties(xtb::xtb PROPERTIES
          IMPORTED_LOCATION "${pkgs.xtb}/lib/libxtb.so"
          INTERFACE_INCLUDE_DIRECTORIES "${pkgs.xtb}/include"
        )
        EOF
      '';
    };

    gfn0 = stdenv.mkDerivation {
      pname = "gfn0";
      version = "0.1.3";
      src = gfn0Src;
      nativeBuildInputs = commonNative ++ [ pkgs.python3 pkgs.python3Packages.pybind11 ];
      buildInputs = [ mctc-lib mstore toml-f xtb ] ++ linalg;
      postPatch = ''
        mkdir -p subprojects
        ln -s ${testDriveSrc} subprojects/test-drive
      '';
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DWITH_TESTS=OFF"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Dxtb_DIR=${xtb}/lib/cmake/xtb"
        "-Dpybind11_DIR=${pkgs.python3Packages.pybind11}/share/cmake/pybind11"
      ];
      postInstall = ''
        for f in $out/lib/cmake/*/*-targets.cmake; do
          sed -i 's#"''${_IMPORT_PREFIX}//nix/store/[^/]*/include"#"''${_IMPORT_PREFIX}/include"#g' "$f" || true
        done
        mkdir -p $out/lib/cmake/gfn0
        cat << 'EOF' > $out/lib/cmake/gfn0/gfn0Config.cmake
        get_filename_component(PACKAGE_PREFIX_DIR "''${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
        include("''${CMAKE_CURRENT_LIST_DIR}/gfn0-targets.cmake")
        file(GLOB _gfn0_module_dirs "''${PACKAGE_PREFIX_DIR}/include/gfn0/*")
        set_property(TARGET gfn0::gfn0 APPEND PROPERTY
          INTERFACE_INCLUDE_DIRECTORIES "''${_gfn0_module_dirs}")
        EOF
      '';
      dontFixup = true;
    };

    gfnff = stdenv.mkDerivation {
      pname = "gfnff";
      version = "0.1.0";
      src = gfnffSrc;
      nativeBuildInputs = commonNative ++ [ pkgs.python3 pkgs.python3Packages.pybind11 ];
      buildInputs = [ mctc-lib mstore toml-f xtb simple-dftd3 dftd4 ] ++ linalg;
      postPatch = ''
        mkdir -p subprojects
        ln -s ${testDriveSrc} subprojects/test-drive
      '';
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DWITH_TESTS=OFF"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Dxtb_DIR=${xtb}/lib/cmake/xtb"
        "-Ds-dftd3_DIR=${simple-dftd3}/lib/cmake/s-dftd3"
        "-Ddftd4_DIR=${dftd4}/lib/cmake/dftd4"
        "-Dpybind11_DIR=${pkgs.python3Packages.pybind11}/share/cmake/pybind11"
      ];
      postInstall = ''
        for f in $out/lib/cmake/*/*-targets.cmake; do
          sed -i 's#"''${_IMPORT_PREFIX}//nix/store/[^/]*/include"#"''${_IMPORT_PREFIX}/include"#g' "$f" || true
        done
        mkdir -p $out/lib/cmake/gfnff
        cat << 'EOF' > $out/lib/cmake/gfnff/gfnffConfig.cmake
        get_filename_component(PACKAGE_PREFIX_DIR "''${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
        include("''${CMAKE_CURRENT_LIST_DIR}/gfnff-targets.cmake")
        file(GLOB _gfnff_module_dirs "''${PACKAGE_PREFIX_DIR}/include/gfnff/*")
        set_property(TARGET gfnff::gfnff APPEND PROPERTY
          INTERFACE_INCLUDE_DIRECTORIES "''${_gfnff_module_dirs}")
        EOF
      '';
      dontFixup = true;
    };

    lwoniom = stdenv.mkDerivation {
      pname = "lwoniom";
      version = "0.1.0";
      src = lwoniomSrc;
      nativeBuildInputs = commonNative ++ [ pkgs.python3 pkgs.python3Packages.pybind11 ];
      buildInputs = [ mctc-lib mstore toml-f xtb gfn0 gfnff ] ++ linalg;
      postPatch = ''
        mkdir -p subprojects
        ln -s ${testDriveSrc} subprojects/test-drive
      '';
      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DWITH_TESTS=OFF"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Dxtb_DIR=${xtb}/lib/cmake/xtb"
        "-Dgfn0_DIR=${gfn0}/lib/cmake/gfn0"
        "-Dgfnff_DIR=${gfnff}/lib/cmake/gfnff"
        "-Dpybind11_DIR=${pkgs.python3Packages.pybind11}/share/cmake/pybind11"
      ];
      postInstall = ''
        for f in $out/lib/cmake/*/*-targets.cmake; do
          sed -i 's#"''${_IMPORT_PREFIX}//nix/store/[^/]*/include"#"''${_IMPORT_PREFIX}/include"#g' "$f" || true
        done
        mkdir -p $out/lib/cmake/lwoniom
        cat << 'EOF' > $out/lib/cmake/lwoniom/lwoniomConfig.cmake
        include("''${CMAKE_CURRENT_LIST_DIR}/lwoniom-targets.cmake")
        EOF
      '';
      dontFixup = true;
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

      nativeBuildInputs = commonNative ++ [ pkgs.python3 pkgs.python3Packages.pybind11 ];
      enableParallelBuilding = false;

      postPatch = ''
        substituteInPlace CMakeLists.txt \
          --replace 'if(NOT TARGET "gfn0::gfn0" AND WITH_GFN0)' 'if(WITH_GFN0)' || true
        python3 -c 'import re
path3 = "src/symmetry_i.c"
with open(path3) as f:
    c3 = f.read()
old_function = "int true(void){ return 1 ; }"
new_function = "static int crest_symmetry_always_true(void){ return 1 ; }"
if c3.count(old_function) != 1:
    raise SystemExit("unexpected symmetry_i.c true() definition")
c3 = c3.replace(old_function, new_function)
c3, count = re.subn(
    r"(\{\s*\"[^\"]+\"\s*,\s*\"[^\"]*\"\s*,\s*)true(\s*\})",
    r"\1crest_symmetry_always_true\2",
    c3,
)
if count == 0:
    raise SystemExit("could not patch symmetry point-group callbacks")
with open(path3, "w") as f:
    f.write(c3)'
        mkdir -p subprojects
        ln -s ${testDriveSrc} subprojects/test-drive
      '';

      buildInputs = [
        xtb
        tblite
        toml-f
        mctc-lib
        mstore
        multicharge
        dftd4
        simple-dftd3
        gfn0
        gfnff
        lwoniom
      ] ++ linalg;

      cmakeFlags = [
        "-DCMAKE_BUILD_TYPE=Release"
        "-DWITH_TESTS=OFF"
        "-DWITH_XHCFF=OFF"
        "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
        "-Dtoml-f_DIR=${toml-f}/lib/cmake/toml-f"
        "-Dmctc-lib_DIR=${mctc-lib}/lib/cmake/mctc-lib"
        "-Dmstore_DIR=${mstore}/lib/cmake/mstore"
        "-Dxtb_DIR=${xtb}/lib/cmake/xtb"
        "-Ds-dftd3_DIR=${simple-dftd3}/lib/cmake/s-dftd3"
        "-Ddftd4_DIR=${dftd4}/lib/cmake/dftd4"
        "-Dgfn0_DIR=${gfn0}/lib/cmake/gfn0"
        "-Dgfnff_DIR=${gfnff}/lib/cmake/gfnff"
        "-Dlwoniom_DIR=${lwoniom}/lib/cmake/lwoniom"
        "-Dpybind11_DIR=${pkgs.python3Packages.pybind11}/share/cmake/pybind11"
      ];

      installPhase = ''
        mkdir -p $out/bin
        cp crest $out/bin/
      '';
    };

  in
  {
    packages = {
      inherit crest xtb tblite mctc-lib mstore simple-dftd3 multicharge dftd4 gfn0 gfnff lwoniom;
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
