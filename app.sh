### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib" --shared
make
make install
rm -fv "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2a"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  shared threads linux-armv4 \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -i -e "s/-O3//g" Makefile
make -j1
make install_sw
cp -avR "${DEPS}/lib"/* "${DEST}/lib/"
rm -fvr "${DEPS}/lib"
rm -fv "${DEST}/lib/libcrypto.a" "${DEST}/lib/libssl.a"
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}/lib/pkgconfig/openssl.pc"
popd
}

### RUBY2 ###
_build_ruby2() {
local VERSION="2.2.2"
local FOLDER="ruby-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://cache.ruby-lang.org/pub/ruby/2.2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

if [ ! -d "target/${FOLDER}-native" ]; then
cp -aR "target/${FOLDER}" "target/${FOLDER}-native"
( . uncrosscompile.sh
  pushd "target/${FOLDER}-native"
  ./configure --prefix="${DEPS}-native" --with-baseruby="/usr/bin/ruby" --enable-shared --disable-static --disable-install-doc
  make
  make install )
fi

pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEST}" --with-baseruby="${DEPS}-native/bin/ruby" --enable-shared --disable-static --disable-install-doc --without-gmp --without-valgrind ac_cv_func_pthread_attr_init=no
make
make install
rm -fv "${DEST}/lib/libruby-static.a"
popd
}

### BUNDLER ###
_build_bundler() {
pushd "${DEST}"
QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc" "${DEST}/bin/gem" install bundler --verbose --install-dir="${DEST}" --no-document
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_openssl
  _build_ruby2
  _package
}
