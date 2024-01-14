#!/bin/bash

# download and extract arknights assets
# $1 = server

script_dir=$(dirname "${BASH_SOURCE[0]}")

starttime=$(date +"%Y-%m-%d %H:%M:%S")

server="${1:-"cn"}"
mode="sprite"
if [[ $server == audio ]]; then
    server="cn"
    mode="audio"
fi

echo "Installing latest assets"
source "${script_dir}/download_bundles.sh" "./bundles" $server $mode

if [[ $? -ne 0 ]]; then
    exit 2
fi

echo "Installing latest asset studio"
source "${script_dir}/download_studio.sh" "./ArknightsStudioCLI"

echo "Unpacking assets"
source "${script_dir}/extract_assets.sh" "." "./bundles" $mode "$starttime"

if [[ $mode == audio ]]; then
    exit 0
fi

echo "Installing flatc and schemas"
source "${script_dir}/download_flatbuffers.sh" "./FBS" $server

echo "Parsing gamedata"
source "${script_dir}/parse_gamedata.sh" "./gamedata" "./assets/torappu/dynamicassets/gamedata" "./FBS"

echo "Completed download"
