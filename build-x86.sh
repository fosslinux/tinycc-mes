#! /bin/sh
set -ex
rm -f i686-unknown-linux-gnu-tcc

# crt1=$(i686-unknown-linux-gnu-gcc --print-file-name=crt1.o)
# crtdir=$(dirname $crt1)

unset C_INCLUDE_PATH LIBRARY_PATH

PREFIX=${PREFIX-usr}
GUIX=${GUIX-$(command -v guix||:)}
MES_PREFIX=${MES_PREFIX-../mes}
MES_PREFIX=${MES_PREFIX-${MESCC%/*}/../share/mes}
TINYCC_SEED=${TINYCC_SEED-../tinycc-seed}
cp $TINYCC_SEED/x86-mes-gcc/crt1.o crt1.o
cp $TINYCC_SEED/x86-mes-gcc/crti.o crti.o
cp $TINYCC_SEED/x86-mes-gcc/crtn.o crtn.o

CC=${CC-i686-unknown-linux-gnu-gcc}
CFLAGS="
-nostdinc
-nostdlib
-fno-builtin
--include=$MES_PREFIX/lib/linux/x86-mes-gcc/crt1.c
--include=$MES_PREFIX/lib/libc+tcc.c
--include=$MES_PREFIX/lib/libtcc1.c
-Wl,-Ttext-segment=0x1000000
"

if [ -z "$interpreter" -a -n "$GUIX" ]; then
    interpreter=$($GUIX environment --ad-hoc patchelf -- patchelf --print-interpreter $(guix build --system=i686-linux hello)/bin/hello)
elif [ -x /lib/ld-linux.so.2 ]; then
    # legacy non-GuixSD support
    interpreter=/lib/ld-linux.so.2
fi
interpreter=${interpreter-interpreter}
export interpreter

mkdir -p $PREFIX/lib
ABSPREFIX=$(cd $PREFIX && pwd)
cp $TINYCC_SEED/x86-mes-gcc/libc+tcc.o $ABSPREFIX/lib
cp $TINYCC_SEED/x86-mes-gcc/libtcc1.o $ABSPREFIX/lib
$CC -g -o i686-unknown-linux-gnu-tcc\
   $CFLAGS\
   -I.\
   -I $MES_PREFIX/lib\
   -I $MES_PREFIX/include\
   -D 'CONFIG_TCCDIR="'$PREFIX'/lib/tcc"'\
   -D 'CONFIG_TCC_CRTPREFIX="'$PREFIX'/lib:{B}/lib:."'\
   -D 'CONFIG_TCC_ELFINTERP="'$interpreter'"'\
   -D 'CONFIG_TCC_LIBPATHS="'$ABSPREFIX'/lib:{B}/lib:."'\
   -D 'CONFIG_TCC_SYSINCLUDEPATHS="'$MES_PREFIX'/include:'$PREFIX'/include:{B}/include"'\
   -D CONFIG_USE_LIBGCC=1\
   -D 'TCC_LIBGCC="'$ABSPREFIX'/lib/libc.a"'\
   -D BOOTSTRAP=1\
   -D CONFIG_TCCBOOT=1\
   -D CONFIG_TCC_STATIC=1\
   -D CONFIG_USE_LIBGCC=1\
   -D ONE_SOURCE=1\
   -D TCC_MES_LIBC=1\
   -D TCC_TARGET_I386=1\
   tcc.c