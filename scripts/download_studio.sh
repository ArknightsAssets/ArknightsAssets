#!/bin/bash

# download the latest assetstudio
# $1 = savepath

savepath="${1:-"./ArknightsStudioCLI"}"

# # wget -q -c -O "/tmp/ArknightsStudioCLI.zip" "https://github.com/aelurum/AssetStudio/releases/latest/download/AssetStudioModCLI_net6_linux64.zip"
# wget -q -O "/tmp/ArknightsStudioCLI.zip" https://ci.appveyor.com/api/buildjobs/2j2epk330ux922wc/artifacts/AssetStudioCLI%2Fbin%2FRelease%2Fnet6.0%2Flinux-x64%2FArknightsStudioCLI-net6-linux64.v1.1.3.zip
# unzip -q -o "/tmp/ArknightsStudioCLI.zip" -d "$savepath"
chmod +x "$savepath/ArknightsStudioCLI"

apt-get install -qq -y dotnet-sdk-6.0
