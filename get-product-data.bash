#!/usr/bin/env bash

curl -s "https://sqlite.org/download.html" |
    grep -ozP '(?s)<!-- Download product data for scripts to read\n\K.*?\n(?= -->)' |
    tr -d '\0'
