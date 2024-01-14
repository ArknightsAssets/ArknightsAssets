#!bin/bash

# run arknights studio for every path
# $1 = savepath

output="${1:-"."}"
bundles="${2:-"./bundles"}"
mode="${3:-"all"}"
minmt="${4:-"1970-01-01 00:00:00"}"

tmpdir="/tmp/akassetstudio/unstructured"
mkdir -p "$tmpdir"

move_or_overwrite() {
    sourcedir=$1
    targetdir=$2
    topdir=$3

    source=$(find "$topdir" -maxdepth 1 -type f)
    if [[ $(echo "$source" | wc -l) == 1 || $topdir == *#* ]]; then
        for file in $source; do
            relpath="${file##$sourcedir/}"
            target="$targetdir/${relpath%%/$(basename $(dirname $relpath))*}/$(basename $relpath)"

            echo "$relpath"
            mkdir -p "$(dirname $target)"
            mv -f "$file" "$target"
        done
    else
        mkdir -p "$targetdir/${topdir##$sourcedir/}/"
        rm -rf "$targetdir/${topdir##$sourcedir/}/*.*"

        for file in $source; do
            echo "${file##$sourcedir/}"
            mv -f "$file" "$targetdir/${file##$sourcedir/}"
        done
    fi
}

for path in $(find "${bundles}" -type f -newerct "$minmt" -name "*.ab"); do
    types=""
    if [[ $mode != audio ]]; then
        types="$types,Sprite,AkPortraitSprite"
    fi
    if [[ $mode != sprite ]]; then
        types="$types,AudioClip"
    fi
    if [[ $path == *gamedata* ]]; then
        types="$types,TextAsset"
    fi

    echo $path
    ArknightsStudioCLI/ArknightsStudioCLI "${path}" -g containerFull -t "${types:1}" -o "$tmpdir" 1>/dev/null
done


for topdir in $(find "$tmpdir" -type f | sed -r 's|/[^/]+$||' | uniq); do
    move_or_overwrite $tmpdir $output $topdir
done
wait

rm -rf "$tmpdir"
