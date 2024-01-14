#!/bin/bash

# parse gamedata
# $1 = savedir, $2 = gamedata folder, $3 = schema folder

savedir="${1:-"./gamedata"}"
gamedata="${2:-"./assets/torappu/dynamicassets/gamedata"}"
fbsdir="${3:-"./FBS"}"

decrypt_aes() {
    # https://github.com/thesadru/ArkPRTS/blob/master/arkprts/assets/bundle.py#L76
    data=$(xxd -p -c 256 "$1")
    mask="554954704169383270484157776e7a7148524d4377506f6e4a4c49423357436c"

    [[ $2 != false ]] && data="${data:256}"

    aes_key="${mask:0:32}"
    aes_iv=""
    for ((i = 0; i < 16; i++)); do
        b="${data:$i*2:2}"
        m="${mask:$((16 + i))*2:2}"
        aes_iv+="$(printf "%02x" $((0x$b ^ 0x$m)))"
    done

    echo -n "${data:32}" | xxd -r -p | openssl enc -d -aes-128-cbc -K "$aes_key" -iv "$aes_iv"
}

decode_fbs() {
    input="/tmp/fbsin/$(basename $1)"
    output="/var/tmp/fbsout/$(basename $1 | cut -d. -f1).json"

    # flatc does not work with plain /tmp for whatever reason
    mkdir -p "/tmp/fbsin"
    mkdir -p "/var/tmp/fbsout"

    dd if=$1 bs=128 skip=1 of=$input 2>/dev/null
    >/dev/null flatc -o "/var/tmp/fbsout" "$2" -- "$input" --json --strict-json --natural-utf8 --defaults-json --unknown-json --raw-binary --force-empty
    cat "$output"
}

try_bson() {
    inputpath=$(mktemp)
    cat - > $inputpath
    ./bsondump --quiet --bsonFile="$inputpath"
    if [ $? -ne 0 ]; then
        cat $inputpath
    fi
}


for file in $(find "${gamedata}" -type f); do
    target="${file##${gamedata}/}"
    mkdir -p $(dirname "${savedir}/${target}")

    if [[ $file == *.txt ]]; then
        cat "${file}" > "${savedir}/${target}"
    elif [[ $file == *.json ]]; then
        jq . "${file}" > "${savedir}/${target}"
    elif [[ $file == *.lua ]]; then
        decrypt_aes "$file" > "${savedir}/${target}"
    elif [[ $file == */levels/obt/*.bytes || $file == */levels/activities/*.bytes ]]; then
        echo $file
        xxd -p -c 256 "$file" | ./bsondump --quiet --bsonFile="$file" > "${savedir}/${target%.bytes}.json"
        if [ $? -ne 0 ]; then
            decode_fbs "${file}" "${fbsdir}/prts___levels.fbs" | jq '.' > "${savedir}/${target%.bytes}.json"
        fi
    elif [[ $file =~ gamedata/(.+_(table|data|const|database))([0-9a-fA-F]{6})? ]]; then
        echo $file
        name="${BASH_REMATCH[1]}"
        if [[ ${BASH_REMATCH[3]} ]]; then
            decode_fbs "${file}" "${fbsdir}/$(basename $name).fbs" | jq '.' > "${savedir}/${name}.json"
        elif [[ $name == "battle/buff_template_data" ]]; then
            ./bsondump --quiet --bsonFile="${file}" | jq '.' > "${savedir}/${name}.json"
        else
            decrypt_aes "${file}" "$([[ $name == enemy_database ]] && false)" | try_bson | jq '.' > "${savedir}/${name}.json"
        fi
    fi || >&2 echo "error parsing $file"
done
