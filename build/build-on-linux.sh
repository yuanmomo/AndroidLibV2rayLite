#!/bin/bash

set -e

current_dir=$(cd "$(dirname "$0")";pwd)
root_dir=${current_dir}/../

# ------------------------------------------------------
# --- set ENV
DOWNLOAD_URL="https://dl.google.com/android/repository/"
SDK_FILE_NAME="sdk-tools-linux-4333796.zip"
GO_FILE_NAME="go1.13.5.linux-amd64.tar.gz"

ANDROID_HOME="/usr/local/android-sdk"
ANDROID_NDK_HOME="${ANDROID_HOME}/ndk-bundle"
PACKAGE_INSTALL_FILE="android_package_to_install"

#cd "${root_dir}" && git pull

# install docker first
if [[ ! $(command -v docker) ]]; then
    echo "自动安装 docker 。。。。。"
    bash <(curl -s -L get.docker.com)
    service docker restart
fi


# ------------------------------------------------------
# --- Download GO into /usr/local/go and set go ENV
# IMPORTANT:  gomobile not support go modules !!!!
if [[ ! $(command -v go) ]]; then
    wget -q https://dl.google.com/go/${GO_FILE_NAME} && tar -C /usr/local -xzf ${GO_FILE_NAME} && rm -f ${GO_FILE_NAME}*

    # update PATH
    echo 'export PATH=${PATH}'":/usr/local/go/bin:/root/go/bin" >> ~/.bashrc
    source ~/.bashrc
fi

# ------------------------------------------------------
# --- Download Android SDK tools into $ANDROID_HOME
if [[ ! $(command -v sdkmanager) ]]; then
    wget -q ${DOWNLOAD_URL}/${SDK_FILE_NAME} && unzip ${SDK_FILE_NAME} -d ${ANDROID_HOME} && rm -rf ${SDK_FILE_NAME}*

    # update PATH
    echo 'export PATH=${PATH}'":${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools" >> ~/.bashrc
    source ~/.bashrc
fi


update_android_sdk=0
for param in "$@"; do
  case $param in
  sdk*)
    update_android_sdk=1
    ;;
  esac
done

if [[ ${update_android_sdk} == "1" ]] ; then
    # ------------------------------------------------------
    # --- install package and NDK
    sdkmanager --verbose --list | awk -f ${root_dir}/build/awk/parse.awk > ${ANDROID_HOME}/${PACKAGE_INSTALL_FILE}
    readarray -t package_names < ${ANDROID_HOME}/${PACKAGE_INSTALL_FILE}
    yes | sdkmanager --verbose --install "${package_names[@]}" | awk -f ${root_dir}/build/awk/reduce.awk
    yes | sdkmanager "ndk-bundle"
fi


GO_PATH_SRC_DIR_IN_DOCKER=/root/go/src/AndroidLibV2rayLite
docker run --name builder --rm \
    -v /usr/local/go:/opt/go \
    -v ${ANDROID_HOME}:/opt/android-sdk \
    -v "${root_dir}"/AndroidLibV2rayLite:${GO_PATH_SRC_DIR_IN_DOCKER} \
    yuanmomo/android-v2ray-build:1.0.0 /bin/bash -vx ${GO_PATH_SRC_DIR_IN_DOCKER}/build-in-docker.sh data dep

