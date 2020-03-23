#!/bin/sh -e
echo "Initialize local valuables"

if [ _${GITHUB_ACTIONS} = _true ]; then
    BUILD_SH=$1
    SRC_PATH=$(pwd)/$2
    OUTPUT_PATH=$(pwd)/$3
else
    BUILD_SH=${1:-build.sh}
    SRC_PATH=/src
    OUTPUT_PATH=/output
fi

BIN_DIR=${3:-output}

echo BUILD_SH: ${BUILD_SH}
echo SRC_PATH: ${SRC_PATH}
echo OUTPUT_PATH: ${OUTPUT_PATH}
echo BIN_DIR: ${BIN_DIR}
echo pwd: $(pwd)

mkdir -p ${OUTPUT_PATH}

tmp_dir=$(mktemp -d)

echo Copying source files
cp -a ${SRC_PATH}/* ${tmp_dir}

cd ${tmp_dir}
ln -s ${OUTPUT_PATH} ${BIN_DIR}

echo Building ${BUILD_SH}
OUTPUT_PATH=${OUTPUT_PATH} ./${BUILD_SH}

echo Copying related libraries
cd ${OUTPUT_PATH}
mkdir -p lib
for prog in *; do
    if [ _${prog} = _lib ]; then
        continue
    fi

    libs=$(ldd $prog | grep '=>' | grep -v 'not found' | cut -d' ' -f3 | sed 's/\.so\..*/\.so/')
    if [ -z "${libs}" ]; then
        continue
    fi
    for lib in ${libs}; do
        if [ ! -z "${lib}" ]; then
            echo $lib
            cp -a ${lib}* lib/
        fi
    done
done

echo Changing library to runtime environment
rm /lib64
/sbin/sln /lib64.runtime /lib64
mv /usr/lib64 /usr/lib64.org
rm -rf /etc/ld.so.*

echo Removing system libraries
for prog in *; do
    if [ _${prog} = _lib ]; then
        continue
    fi

    libs=$(ldd $prog | grep '=>' | grep -v 'not found' | cut -d' ' -f3 | sed 's/\.so\..*/\.so/')
    if [ -z "${libs}" ]; then
        continue
    fi
    for lib in ${libs}; do
        lib=$(basename ${lib})
        if [ ! -z ${lib} ]; then
            echo $lib
            rm -f lib/${lib}*
        fi
    done
done

echo OUTPUT_PATH:
cd ${OUTPUT_PATH}
ls -laR
