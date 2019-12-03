#!/usr/bin/env bash

################ 常量配置 ################
set -o errexit
set -o pipefail
set -o nounset

# Set magic variables for current file & dir
__dir=$(cd "$(dirname "$0")";pwd)

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
go get -u github.com/jteeuwen/go-bindata/...
go get -u github.com/golang/protobuf/protoc-gen-go/...
go get -u -insecure v2ray.com/core
go get -u golang.org/x/mobile/cmd/...

# copy self to GOPATH
target=${GOPATH}/src/AndroidLibV2rayLite

mkdir -p ${target}
cp -rfv "${__dir}"/* ${target}/
# down dep
go get AndroidLibV2rayLite

################ 下载 assets  ################
bash gen_assets.sh download

# 编译 tun2socks
cd shippedBinarys && make  shippedBinary

# 编译 aar
cd ${target}
gomobile init && gomobile bind -v  -tags json .

