#!/usr/bin/env bash

if [[ ! -d source ]]; then
    printf 'Error: Subdirectory "source" not found. Start the script from the project root!\n' >&2
    exit 1
fi

import_release() {
    local -r year=$1 package=$2 version=$3 changelog=$4
    local zipfile url temp_ram_dir

    printf -v zipfile '%s.zip' $package
    printf -v url 'https://sqlite.org/%04d/%s' $year $zipfile
    printf 'Processing %s\n' $url

    if wget --quiet -O $zipfile $url && unzip -qqo -j $zipfile -d source; then
        local filesize=$(stat --printf '%s' "$zipfile")
        local sha3=$(cksum -a sha3 -l 256 "$zipfile" | awk '{print $4}')
        rm $zipfile

        (cd source && cksum -a sha3 -l 256 *.[ch] > sqlite3.sha3sum)

        user_name=$(git config get user.name)
        user_email=$(git config get user.email)
        signoff="$user_name <$user_email>"

        git add source
        git config --local trailer.where end
        git commit --quiet \
                --message "chore(deps): import sqlite release $version" \
                --trailer "Source: $url" \
                --trailer "Changelog: $changelog" \
                --trailer "Signed-off-by: $signoff" &&
        printf 'PRODUCT,%s,%s/%s,%s,%s\n' $version $year $zipfile $filesize $sha3 >> tools/product-data.csv
    else
        printf 'Error: Failed to download or extract %s\n' $package >&2
        return 1
    fi
}

import_releases() {
    local date version
    while read -r date version; do
        local -i year major minor patch
        year=${date%%-*}
        IFS=. read major minor patch <<<$version

        local package changelog
        printf -v package 'sqlite-amalgamation-%d%02d%02d00' $major $minor $patch
        printf -v changelog 'https://sqlite.org/releaselog/%d_%d_%d.html' $major $minor $patch

        import_release $year $package $version $changelog
    done
}

import_releases <<EOF
2026-06-26	3.53.3
EOF
