#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"


ASSETS_DIR=${__dir}/assets

if [[ ! -d ${ASSETS_DIR} ]] ; then
  mkdir -p ${ASSETS_DIR}
fi

download_dat () {
    wget -qO - https://api.github.com/repos/v2ray/geoip/releases/latest \
    | grep browser_download_url | cut -d '"' -f 4 \
    | wget -i - -O $ASSETS_DIR/geoip.dat

    wget -qO - https://api.github.com/repos/v2ray/domain-list-community/releases/latest \
    | grep browser_download_url | cut -d '"' -f 4 \
    | wget -i - -O $ASSETS_DIR/geosite.dat
}

ACTION="${1:-}"
if [[ -z $ACTION ]]; then
    ACTION=download
fi

case $ACTION in
    "download") download_dat;;
esac
