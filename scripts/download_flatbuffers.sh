#!/bin/bash

# download flatc and flatbuffers
# $1 = savedir, $2 = server

savedir="${1:-"./FBS"}"
case $2 in
    "en") branch="YoStar";;
    "jp") branch="YoStar";;
    "kr") branch="YoStar";;
    *) branch="main";;
    # cn is default
esac

wget -q -c -O "/tmp/OpenArknightsFBS-${branch}.zip" "http://github.com/MooncellWiki/OpenArknightsFBS/zipball/${branch}/"
unzip -q -d "/tmp/OpenArknightsFBS-${branch}" "/tmp/OpenArknightsFBS-${branch}.zip"
fbsdirectory=$(find /tmp/OpenArknightsFBS-${branch} -name "FBS")
rm -rf "${savedir}"
mv "${fbsdirectory}" "${savedir}"
rm -r "/tmp/OpenArknightsFBS-${branch}"

# mooncell flatbuffers unfortunately do not work
apt-get -qq install -y flatbuffers-compiler openssl xxd
chmod +x ./bsondump
