#!/bin/bash

set -e

# param check
echo "check params ...."
cmdname=$(basename $0)
useage(){
    cat << USAGE  >&2
Usage:
    $cmdname [sdk] [data] [dep] [ h | help]
    sdk       :       download latest Android SDK and NDK.
    data      :       download latest geoip.dat and geosite.dat files.
    depi      :       update dependencies of AndroidLibV2rayLite.
    h | help  :       show help.
USAGE
}
if [[ $# == 0 ]] ; then
    useage
fi

update_android_sdk=0
download_geo_data=""
update_go_dep=""
for param in "$@"; do
  case $param in
  sdk*)
    update_android_sdk=1
    ;;
  data*)
    download_geo_data="data"
    ;;
  dep*)
    update_go_dep="dep"
    ;;
  h*)
    useage
    exit 1
    ;;
  esac
done


echo "set env ......"
current_dir=$(cd "$(dirname "$0")";pwd)
root_dir=${current_dir}/..

# ------------------------------------------------------
# --- set ENV
DOWNLOAD_URL="https://dl.google.com/android/repository"
SDK_FILE_NAME="sdk-tools-linux-4333796.zip"
GO_FILE_NAME="go1.13.5.linux-amd64.tar.gz"

ANDROID_HOME="/usr/local/android-sdk"
ANDROID_NDK_HOME="${ANDROID_HOME}/ndk-bundle"
PACKAGE_INSTALL_FILE="android_package_to_install"

cd "${root_dir}" && git pull

# install docker first
if [[ ! $(command -v docker) ]]; then
    echo "install docker 。。。。。"
    bash <(curl -s -L get.docker.com)
    service docker restart
fi


# ------------------------------------------------------
# --- Download GO into /usr/local/go and set go ENV
# IMPORTANT:  gomobile not support go modules !!!!
if [[ ! $(command -v go) ]]; then
    echo "install go  ....."
    wget -q https://dl.google.com/go/${GO_FILE_NAME} && tar -C /usr/local -xzf ${GO_FILE_NAME} && rm -f ${GO_FILE_NAME}*

    # update PATH
    echo 'export PATH=${PATH}'":/usr/local/go/bin:/root/go/bin" >> ~/.bashrc
    source ~/.bashrc
fi

# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_HOME
if [[ ! $(command -v sdkmanager) ]]; then
    echo "install android sdk and sdkmanager ....."
    wget -q ${DOWNLOAD_URL}/${SDK_FILE_NAME} && unzip ${SDK_FILE_NAME} -d ${ANDROID_HOME} && rm -rf ${SDK_FILE_NAME}*

    # update PATH
    echo 'export PATH=${PATH}'":${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools" >> ~/.bashrc
    source ~/.bashrc
fi

# ------------------------------------------------------
# --- Install open-jdk
if [[ ! $(command -v java) ]]; then
    echo "install openjdk-8-jdk ....."

   # Debian(Ubuntu) or RHEL(CentOS)
    cmd="apt"
    if [[ $(command -v yum) ]]; then
    	cmd="yum"
    fi

    # update first
    ${cmd} -y update
    if [[ ${cmd} == "apt" ]]; then
        ${cmd} -y upgrade
    fi

    ${cmd} install -y unzip openjdk-8-jdk
fi

if [[ ${update_android_sdk} == "1" ]] ; then
    # ------------------------------------------------------
    # --- install package and NDK
    echo "sdkmanager install tools ....."

    sdkmanager --verbose --list | awk -f ${root_dir}/build/awk/parse.awk > ${ANDROID_HOME}/${PACKAGE_INSTALL_FILE}
    readarray -t package_names < ${ANDROID_HOME}/${PACKAGE_INSTALL_FILE}
    yes | sdkmanager --verbose --install "${package_names[@]}" | awk -f ${root_dir}/build/awk/reduce.awk
    yes | sdkmanager "ndk-bundle"
fi


echo "docker run and build aar ....."
GO_PATH_SRC_DIR_IN_DOCKER=/root/go/src/AndroidLibV2rayLite
docker run --name builder --rm \
    -v /usr/local/go:/opt/go \
    -v ${ANDROID_HOME}:/opt/android-sdk \
    -v "${root_dir}"/AndroidLibV2rayLite:${GO_PATH_SRC_DIR_IN_DOCKER} \
    yuanmomo/android-v2ray-build:1.0.0 /bin/bash -vx ${GO_PATH_SRC_DIR_IN_DOCKER}/build-in-docker.sh ${download_geo_data} ${update_go_dep}

