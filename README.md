# crest-nix

Nix flake for building **CREST 3.0.2** with the CMake build used by upstream.

## Build

```sh
nix build .#crest
```

Or enter a shell containing the built executable:

```sh
nix develop
crest --help
```

## Dependency policy

The source is fetched from the upstream `v3.0.2` tag with
`fetchSubmodules = true`. This is intentional: CREST's CMake configuration
prefers the source trees in `subprojects/`, and the upstream Git tree records
the exact submodule revisions that were tested together.

Do not replace these with independently selected "latest" versions of
`tblite`, `toml-f`, `gfn0`, `gfnff`, or the other Fortran subprojects.
That can mix incompatible Fortran module interfaces.

The build uses upstream CMake options, enables the bundled calculator
backends, and disables the upstream unit-test targets for the initial
packaging pass. BLAS/LAPACK is provided by OpenBLAS.

## Initial source hash

The source hash is currently set to `lib.fakeHash` because enabling recursive
submodule fetching changes the fixed-output source hash from the old
non-submodule archive hash.

On the first build, Nix will report the expected hash. Replace
`pkgs.lib.fakeHash` in `flake.nix` with that value, then run the build again.
This is a one-time source pinning step; the submodule revisions themselves
are already fixed by the upstream `v3.0.2` tag.
