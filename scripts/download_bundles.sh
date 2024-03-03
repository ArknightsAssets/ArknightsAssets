#!/bin/bash

# download arknights asset bundles, requires jq
# $1 = savedir, $2 = server, $3 = mode (sprite/audio), $4 = force

savedir="${1:-"./bundles"}"
mode="${3:-"all"}"
force="${4:-""}"

# base_url = hu of network config
case $2 in
    "en") network_config_url="https://ak-conf.arknights.global/config/prod/official/network_config";;
    "jp") network_config_url="https://ak-conf.arknights.jp/config/prod/official/network_config";;
    "kr") network_config_url="https://ak-conf.arknights.kr/config/prod/official/network_config";;
    "tw") network_config_url="https://ak-conf.txwy.tw/config/prod/official/network_config";;
    "bili") network_config_url="https://ak-conf.hypergryph.com/config/prod/b/network_config";;
    *) network_config_url="https://ak-conf.hypergryph.com/config/prod/official/network_config";;
    # cn is default
esac

network_config=$(curl -s "$network_config_url" | jq -r ".content")
network_urls=$(echo $network_config | jq -r ".configs[$(echo $network_config | jq ".funcVer")].network")
version_url=$(echo $network_urls | jq -r ".hv" | sed "s/{0}/Android/g")
res_version=$(curl -s "$version_url" | jq -r ".resVersion")
assets_url="$(echo $network_urls | jq -r ".hu")/Android/assets/${res_version}"

mkdir -p "$savedir"

encode_path() { echo "$1" | sed -e "s|/|_|g" -e "s|#|__|" -e "s|\..*|.dat|g"; }

download_file() {
    local path="$1"
    local formatted_path=$(encode_path "$path")

    wget -q -c -P "/tmp/akassets" "${assets_url}/${formatted_path}"
    if [[ $path == *.ab ]]; then
        unzip -q -o "/tmp/akassets/${formatted_path}" -d "$savedir"
        rm "/tmp/akassets/${formatted_path}"
    else
        mkdir -p "$(dirname "${savedir}/${path}")"
        mv "/tmp/akassets/${formatted_path}" "${savedir}/${path}"
    fi
    echo "${path}"
}

if [[ $(cat "${savedir}/hot_update_list.json" | jq -r ".versionId") == $res_version && $force != "--force" ]]; then
    >&2 echo "Up to date!"
    exit 2
fi;

declare -A old_hash
while IFS="," read -r path hash; do
    old_hash[$path]=$hash
done < <(cat "${savedir}/hot_update_list.json" | jq -r -c '.abInfos[] | "\(.name),\(.hash)"')

curl -s "${assets_url}/hot_update_list.json" | jq . > "${savedir}/hot_update_list.json"
while IFS="," read -r path hash; do
    if [[ $mode == sprite && $path == *audio* ]]; then
        continue
    elif [[ $mode == audio && $path != *audio* ]]; then
        continue
    fi;

    if [[ "${hash}" != "${old_hash[$path]}" ]]; then
        download_file "$path"
    fi
done < <(cat "${savedir}/hot_update_list.json" | jq -r -c '.abInfos[] | "\(.name),\(.hash)"')
wait
