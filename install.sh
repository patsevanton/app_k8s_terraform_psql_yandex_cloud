#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

list_command_available=(yc terraform kubectl helm)

for i in ${list_command_available[*]}
do
    if ! command -v $i &> /dev/null
    then
        echo "$i could not be found"
        exit
    fi
done
