#!/bin/sh -e

get_link_path() {
    local path=$1
    local target=$(readlink ${src})
    if echo ${target} | grep -q '^/'; then
        echo ${target}
    else
        echo $(dirname ${path})/${target}
    fi
}

copy() {
    local src=$1
    local dst_dir=$2
    if [ -L ${src} ]; then
        local target=$(readlink ${src})
        if echo ${target} | grep -q '^../../lib64/'; then
            target=${target:12}
            ln -sf ${target} $dst_dir/$(basename ${so})
            return
        fi
    fi
    echo "Copying: ${src}"
    cp -an ${src} ${dst_dir}/
}


rcopy() {
    local src=$1
    local dst_dir=$2
    if [ -L ${src} ]; then
        local target=$(get_link_path ${src})
        rcopy ${target} ${dst_dir}
    fi
    copy ${src} ${dst_dir}
}

rrm() {
    local src=$1
    if [ -L ${src} ]; then
        local target=$(get_link_path ${src})
        if ! echo ${target} | grep -q '^/'; then
            rrm ${target}
        fi
    fi
    echo "Removing ${src}"
    rm -f ${src}
}

disp () {
    echo "------------------------------"
    echo "[*] $*"
    echo "------------------------------"
}

main() {
    disp "Initialize local valuables"

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

    local tmp_dir=$(mktemp -d)

    disp "Copying source files"
    cp -a ${SRC_PATH}/* ${tmp_dir}

    cd ${tmp_dir}
    ln -s ${OUTPUT_PATH} ${BIN_DIR}

    disp "Building ${BUILD_SH}"
    OUTPUT_PATH=${OUTPUT_PATH} bash -x ./${BUILD_SH}

    disp "Copying related libraries"
    cd ${OUTPUT_PATH}
    mkdir -p lib
    for prog in $(find . -type f); do
        if [ -L ${prog} ]; then
            continue
        fi
        libs=$(ldd $prog | grep '=>' | grep -v 'not found' | cut -d' ' -f3)
        if [ -z "${libs}" ]; then
            continue
        fi
        for lib in ${libs}; do
            if [ ! -z "${lib}" ]; then
                rcopy ${lib} lib
            fi
        done
    done

    disp "Changing system library to runtime environment"
    rm -rf /lib64 /usr/lib64
    /sbin/sln /lib64.runtime /lib64
    rm -rf /etc/ld.so.*

    disp "Removing system libraries"
    for prog in $(find . -type f); do
        if [ -L ${prog} ]; then
            continue
        fi
        if [ ! -e ${prog} ]; then
            continue
        fi
        libs=$(ldd $prog | grep '=>' | grep -v 'not found' | cut -d' ' -f3)
        if [ -z "${libs}" ]; then
            continue
        fi
        for lib in ${libs}; do
            rrm lib/$(basename ${lib})
        done
    done

    disp "OUTPUT:"
    cd ${OUTPUT_PATH}
    ls -laR
}

main
