# crux-bitcode

`crux-bitcode` is a CRUX Linux Docker image to make generating LLVM bitcode from (some) open-source software easy by using CRUX's ports system and GLLVM.
`build-bitcode.sh` can build software in the official ports tree (with some caveats) into bitcode.

LLVM/Clang versions: 16.0.6 (default), 21.1.0, 22.1.0.

## Requirements
Docker.
The first run may be slow as the (large) image is downloaded.

## Usage
1. Create a list of desired ports in a file `pkgs.txt` (modify included file).
   (The full list of possibilities can be seen by running `ls ports/*/`.)
2. Run `./build-bitcode.sh` (defaults to LLVM 16.0.6).
   - Pick another version with `-v`: `./build-bitcode.sh -v 21.1.0` or `-v 22.1.0`.
3. unzip the generated `bitcode-XYZ.zip`.

## Building the LLVM 21.1.0 / 22.1.0 images
The `21.1.0` and `22.1.0` images source-build clang+compiler-rt inside CRUX 3.5
using the upstream `llvm-project-<ver>.src.tar.xz` monorepo tarball, then
register stub CRUX packages so transitive `Depends on: llvm` (e.g. mesa3d → qt5)
is satisfied without dragging in the old in-port LLVM. Build them locally with:

```
cd image
docker build -f Dockerfile.src --build-arg LLVM_VERSION=22.1.0 \
  -t wangjiaweiuts/crux-bitcode:22.1.0 .
docker build -f Dockerfile.src --build-arg LLVM_VERSION=21.1.0 \
  -t wangjiaweiuts/crux-bitcode:21.1.0 .
```

The build is heavy (LLVM compile takes ~1–2h on a desktop, link parallelism
capped at 2 to keep RAM under ~16 GB). Other versions can be built the same
way as long as upstream publishes a matching `llvm-project-<ver>.src.tar.xz`.

An `info.txt` file is provided alongside the bitcode files containing (an estimate of) the lines of C/C++ code used to generate each bitcode file.
This is calculated by counting the lines of code in the files mentioned in the debug information.
`info.txt` also includes the user-defined `CFLAGS` and `CXXFLAGS`.

## Customisation
* `build-bitcode.sh` copies `ports` into the container, so ports can be modified, and new ports can be created or copied from elsewhere.
* `build-bitcode.sh` copies `pkgmk.conf` into the container (run the image and `man pkgmk.conf` for more information).


## Caveats
Some ports may not respect `CFLAGS`/`CXXFLAGS` nor `CC`/`CXX`.
The image attempts to resolve this by intercepting calls to the compiler (see `image/cc.lua`, `image/cxx.lua`).
Some ports may need to have their `Pkgfile` modified, or a patch added, if problems arise.

### Packages that cannot be built
These packages have some known problem building bitcode or building bitcode according to user parameters.
They can still be used as dependencies though.

* `nss`: can produce bitcode, but not with user-defined `CFLAGS`.
* `firefox`: appears to fail at the last step; needs investigation.
* `qt5`: does not produce bitcode for some/all binaries; needs investigation
  * Can be used as a dependency
* `qownnotes`: same problem as `qt5`
* `bc`: will not build on Apple Silicon
  * ARM build may be worthwhile

### LLVM/Clang version
If LLVM or Clang (or their runtime dependencies) are included in `pkgs.txt`, then version 10 is used.
The `ports` directory is "frozen" (modulo required fixes) whereas the `image/ports` directory is not.
LLVM and Clang (and dependencies) in `image/ports` are updated as necessary.

Thus there is a tension where LLVM/Clang ports, when building bitcode, are of different versions to the included LLVM/Clang.
If LLVM (or Clang) is built, explicitly or as a dependency, the container will use the newly built LLVM (or Clang) and not the one included in the image.
This can be an older version.

## TODO
* Ability to run `build-bitcode.sh` from anywhere.
* Command line options for `build-bitcode.sh` and `build-bitcode.lua`.
* Reduce image size.
* Test more ports.
* Remove more non-C/C++ ports.
* Nicer error handling.
* Would be nice if sources are archived to "freeze" the port tree.
* Always use included LLVM/Clang, never a version built by the user.
