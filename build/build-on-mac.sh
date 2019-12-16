#!/usr/bin/env bash

################ 常量配置 ################
set -o errexit
set -o pipefail
set -o nounset

# Set magic variables for current file & dir
__dir=$(cd "$(dirname "$0")";pwd)
download_data=0
update_go_dep=0

for param in "$@"; do
  case $param in
  data*)
    download_data=1
    ;;
  dep*)
    update_go_dep=1
    ;;
  esac
done


################ 监测是否配置 android 的 sdk ################
if [[ ! ${ANDROID_HOME} ]] ; then
  echo "Please set env ANDROID_HOME"
  exit 1
fi
if [[ ! ${ANDROID_NDK_HOME} ]] ; then
  echo "Please set env ANDROID_NDK_HOME"
  exit 1
fi


################ 安装 go ################
if [[ ! $(command -v go) ]] ; then
  echo "Install go first ..... "
  brew install go
fi
# 配置 GO 相关的环境变量
export GOROOT="$(dirname $(dirname $(greadlink -f $(which go))))"
export GOBIN=$GOROOT/bin
export GOPATH=~/go
#启用 GO module
export GO111MODULE=off
export GOPROXY=direct
# 添加 go 的路径到 PATH
export PATH=$GOBIN:$GOPATH/bin:$PATH


################ go 下载依赖  ################
if [[ ${update_go_dep} == "1" ]] ; then
  echo "Update go dep......"
  # download dep
  go get -u github.com/golang/protobuf/protoc-gen-go/...
  go get -u golang.org/x/mobile/cmd/...
  go get -u github.com/jteeuwen/go-bindata/...

  go get -u -insecure v2ray.com/core

fi

# copy self to GOPATH
target=${GOPATH}/src/AndroidLibV2rayLite

mkdir -p ${target}
cp -rfv "${__dir}"/* ${target}/
# down dep
go get AndroidLibV2rayLite

################ 下载 assets  ################
if [[ ${download_data} == "1" ]] ; then
  echo "Download geo data....."
  bash gen_assets.sh download
fi

# 编译 tun2socks
cd shippedBinarys && make shippedBinary

cd ${target}
for arg in "$@"; do
  case $arg in
#  ios*)
#    # 编译 ios framework
#    echo "compile ios framework"
#    gomobile bind -target=ios
#    ;;
  android*)
    # 编译 aar
    echo "compile aar"
    gomobile init && gomobile bind -v  -tags json .
    ;;
  esac
done



