#!/usr/bin/env sh
#
# Copyright 2019-2022 Zhenfu Shi (i0ntempest)
# Version 0.1.0
#

move() {
    if [ ! -d "$1" ]; then
        echo "Input is not a directory!" >&2
        exit 1
    fi
    [ -d ~/Pictures/waifu2x/1.5x ] || mkdir -p ~/Pictures/waifu2x/1.5x
    [ -d ~/Pictures/waifu2x/2x ] || mkdir -p ~/Pictures/waifu2x/2x
    [ -d ~/Pictures/waifu2x/3x ] || mkdir -p ~/Pictures/waifu2x/3x
    [ -d ~/Pictures/waifu2x/4x ] || mkdir -p ~/Pictures/waifu2x/4x
    [ -d ~/Pictures/waifu2x/Output ] || mkdir -p ~/Pictures/waifu2x/Output
    # Your monitor width
    master_res_width=3840
    crit4x_width=$(awk -v num="$master_res_width" 'BEGIN { print (num/3) }')
    crit3x_width=$(awk -v num="$master_res_width" 'BEGIN { print (num/2) }')
    crit2x_width=$(awk -v num="$master_res_width" 'BEGIN { print (num/1.5) }')
    errors=0
    total=0
    cntnoprocess=0
    cnt1_5x=0
    cnt2x=0
    cnt3x=0
    cnt4x=0
    for file in "$1"/*; do
        echo "Processing: ""$file"
        local width=$(identify -format "%w" "$file")
        if [ "$?" != 0 ] || [ -z "$width" ]; then
            errors=$(awk -v num="$errors" 'BEGIN { print (num+1) }')
            continue
        fi
        if [ "$(awk -v width="$width" -v crit="$crit4x_width" 'BEGIN { print (width<crit) }')" -eq 1 ]; then
            mv "$file" ~/Pictures/waifu2x/4x/
            cnt4x=$(awk -v num="$cnt4x" 'BEGIN { print (num+1) }')
        elif [ "$(awk -v width="$width" -v crit="$crit3x_width" 'BEGIN { print (width<crit) }')" -eq 1 ]; then
            mv "$file" ~/Pictures/waifu2x/3x/
            cnt3x=$(awk -v num="$cnt3x" 'BEGIN { print (num+1) }')
        elif [ "$(awk -v width="$width" -v crit="$crit2x_width" 'BEGIN { print (width<crit) }')" -eq 1 ]; then
            mv "$file" ~/Pictures/waifu2x/2x/
            cnt2x=$(awk -v num="$cnt2x" 'BEGIN { print (num+1) }')
        elif [ "$(awk -v width="$width" -v crit="$master_res_width" 'BEGIN { print (width<crit) }')" -eq 1 ]; then
            mv "$file" ~/Pictures/waifu2x/1.5x/
            cnt1_5x=$(awk -v num="$cnt1_5x" 'BEGIN { print (num+1) }')
        else
            cntnoprocess=$(awk -v num="$cntnoprocess" 'BEGIN { print (num+1) }')
        fi
        total=$(awk -v num="$total" 'BEGIN { print (num+1) }')
    done
    echo "Summary:"
    echo "Successfully processed ""$total"" images"
    echo "No upscaling needed for ""$cntnoprocess"" image(s), not moved"
    echo "Moved ""$cnt1_5x"" image(s) for 1.5x upscale"
    echo "Moved ""$cnt2x"" image(s) for 2x upscale"
    echo "Moved ""$cnt3x"" image(s) for 3x upscale"
    echo "Moved ""$cnt4x"" image(s) for 4x upscale"
    if [ "$errors" -ne 0 ]; then
        echo "Encountered ""$errors"" errors during processing" >&2
        exit 2
    fi
}

if [ -z "$1" ]; then
    echo "Input or drag a directory containing images:"
    read imgpath
    move "$imgpath"
else
    move "$1"
fi
