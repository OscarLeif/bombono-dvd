#!/usr/bin/env bash
# Run from an MSYS2 UCRT64 shell. Dependencies stay inside the checkout.
set -euo pipefail
cd "$(dirname "$0")/../.."
root="$PWD"
prefix="$root/build-windows/deps"
sources="$root/build-windows/sources"
mkdir -p "$prefix" "$sources"
export PATH="/ucrt64/bin:/usr/bin:$PATH"
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:/ucrt64/lib/pkgconfig"
jobs="${JOBS:-4}"

fetch() {
    local url="$1" archive="$2"
    if [[ ! -f "$sources/$archive" ]]; then
        curl --fail --location --retry 3 "$url" -o "$sources/$archive.part"
        mv "$sources/$archive.part" "$sources/$archive"
    fi
}

build_gtkmm() {
    fetch https://download.gnome.org/sources/gtkmm/2.24/gtkmm-2.24.5.tar.xz gtkmm-2.24.5.tar.xz
    cd "$sources"
    [[ -d gtkmm-2.24.5 ]] || tar -xf gtkmm-2.24.5.tar.xz
    cd gtkmm-2.24.5
    ./configure --prefix="$prefix" --disable-static --disable-documentation \
        --disable-maintainer-mode CXXFLAGS='-O2 -std=c++11'
    make -j"$jobs"
    make install
}

build_libxmlpp() {
    fetch https://download.gnome.org/sources/libxml++/2.42/libxml++-2.42.3.tar.xz libxml++-2.42.3.tar.xz
    cd "$sources"
    [[ -d libxml++-2.42.3 ]] || tar -xf libxml++-2.42.3.tar.xz
    cd libxml++-2.42.3
    meson setup _build --prefix="$(cygpath -m "$prefix")" --libdir=lib \
        --buildtype=release -Dmaintainer-mode=false -Dbuild-documentation=false \
        -Dbuild-examples=false -Dbuild-tests=false
    meson compile -C _build -j "$jobs"
    meson install -C _build
}

build_ffmpeg() {
    fetch https://ffmpeg.org/releases/ffmpeg-3.4.13.tar.xz ffmpeg-3.4.13.tar.xz
    cd "$sources"
    [[ -d ffmpeg-3.4.13 ]] || tar -xf ffmpeg-3.4.13.tar.xz
    cd ffmpeg-3.4.13
    ./configure --prefix="$prefix" --target-os=mingw32 --arch=x86_64 \
        --enable-shared --disable-static --disable-doc --disable-x86asm \
        --disable-autodetect --extra-cflags='-std=gnu11 -Wno-incompatible-pointer-types'
    # GCC 16 can emit out-of-range immediate shifts for the old "ic" constraint.
    # A byte-sized count in CL preserves x86's masked-shift semantics.
    sed -i 's/"ic" ((uint8_t)(-s))/"c" ((uint8_t)(-s))/' libavcodec/x86/mathops.h
    make -j"$jobs"
    make install
}

build_boost() {
    fetch https://archives.boost.io/release/1.74.0/source/boost_1_74_0.tar.bz2 boost_1_74_0.tar.bz2
    cd "$sources"
    [[ -d boost_1_74_0 ]] || tar -xf boost_1_74_0.tar.bz2
    cd boost_1_74_0
    # Build b2 with MinGW rather than letting bootstrap.bat select MSVC.
    MSYS2_ARG_CONV_EXCL=/c cmd.exe /c bootstrap.bat gcc
    ./b2.exe -j"$jobs" toolset=gcc variant=release link=static threading=multi \
        address-model=64 cxxstd=11 --layout=system --with-filesystem --with-system \
        --with-regex --with-test --prefix="$(cygpath -m "$prefix")" install
}

case "${1:-gtkmm}" in
    gtkmm) build_gtkmm ;;
    libxmlpp) build_libxmlpp ;;
    ffmpeg) build_ffmpeg ;;
    boost) build_boost ;;
    *) echo "Usage: $0 {gtkmm|libxmlpp|ffmpeg|boost}" >&2; exit 2 ;;
esac
