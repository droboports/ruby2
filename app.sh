### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -fv "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
cp -vfaR "${DEPS}/lib"/* "${DEST}/lib/"
rm -vfr "${DEPS}/lib"
rm -vf "${DEST}/lib/libcrypto.a" "${DEST}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### RUBY2 ###
_build_ruby2() {
local VERSION="2.2.3"
local FOLDER="ruby-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://cache.ruby-lang.org/pub/ruby/2.2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  ./configure --prefix="${DEPS}-native" --with-baseruby="/usr/bin/ruby" \
    --enable-shared --disable-static --disable-install-doc
  make
  make install )
fi

pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man" \
  --with-baseruby="${DEPS}-native/bin/ruby" --enable-shared --disable-static \
  --disable-install-doc --without-gmp --without-valgrind \
  ac_cv_func_pthread_attr_init=no
make
make install
rm -fv "${DEST}/lib/libruby-static.a"
popd
}

### BUNDLER ###
_build_bundler() {
pushd "${DEST}"
QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc" \
  "${DEST}/bin/gem" install bundler --verbose --install-dir="${DEST}" --no-document
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_ruby2
  _build_bundler
  _package
}
