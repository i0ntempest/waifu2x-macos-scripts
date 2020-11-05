#!/usr/bin/env sh
#
# Copyright 2019-2020 Zhenfu Shi (i0ntempest)
# Version 0.5.1
#

upscale() {
    if [ -n "$(ls -A ~/Pictures/waifu2x/"$1"x/ 2>/dev/null)" ]; then
        if [ "$(awk -v usfactor="$1" 'BEGIN { print (usfactor>4||usfactor<1) }')" -eq 1 ]; then
            echo "Scaling factor is invalid or out of range, only values between 1 and 4 are supported" >&2
            err=1;return
        fi
        if [ "$(awk -v usfactor="$1" 'BEGIN { lg = log(usfactor) / log(2); print (lg == int(lg))}')" -eq 1 ]; then
        #if (( ("$1" & ("$1" - 1)) == 0 )); then # bashism right here
            local usfactor="$1" # integer
        else
            if [ -z "$(which convert)" ]; then
                echo "Any scaling factors other than 2 and 4 requires 'convert' program from ImageMagick but it doesn't seem to be in your system." >&2
                err=2;return
            fi
            if [ "$(awk -v usfactor="$1" 'BEGIN { print (usfactor<2) }')" -eq 1 ]; then
                local usfactor=2
                local dsfactor=$(awk "BEGIN { print $1/2*100 }") # percentage
            else
                local usfactor=4
                local dsfactor=$(awk "BEGIN { print $1/4*100 }") # percentage
            fi
        fi
        echo "$1"x upscaling in progress...
        mkdir -p ~/Pictures/waifu2x/Output/.temp
        for file in ~/Pictures/waifu2x/"$1"x/*; do
            local filename="${file##*/}"; local filename="${filename%.*}"_cunet_anime_noise1_"$usfactor"x
            waifu2x --model cunet -s "$usfactor" -n 1 -i "$file" -o ~/Pictures/waifu2x/Output/.temp/"$filename".png
            if [ "$?" != 0 ];then
                err=3;echo "Failed to upscale: $file >&2";continue
            fi
            if [ -n "$dsfactor" ];then
                echo "Downscaling to $dsfactor%"
                convert ~/Pictures/waifu2x/Output/.temp/"$filename".png -resize "$dsfactor"% ~/Pictures/waifu2x/Output/.temp/"$filename"_ds"$dsfactor"%.png
                if [ "$?" != 0 ]; then
                    err=4;echo "Failed to downscale: $file" >&2
                else
                    echo "Downscaled image saved: ~/Pictures/waifu2x/Output/.temp/""$filename""_ds""$dsfactor""%.png"
                fi
                rm ~/Pictures/waifu2x/Output/.temp/"$filename".png
            fi
        done
        if [ -n "$(ls -A ~/Pictures/waifu2x/Output/.temp/ 2>/dev/null)" ]; then
            echo "Moving upscaled images to Output folder"
            mv ~/Pictures/waifu2x/Output/.temp/* ~/Pictures/waifu2x/Output/
        fi
        rm -rf ~/Pictures/waifu2x/Output/.temp
        echo "$1"x upscaling completed
    else
        echo "No files to upscale ""$1""x"
    fi
}

[ -d ~/Pictures/waifu2x/1.5x ] || mkdir -p ~/Pictures/waifu2x/1.5x
[ -d ~/Pictures/waifu2x/2x ] || mkdir -p ~/Pictures/waifu2x/2x
[ -d ~/Pictures/waifu2x/3x ] || mkdir -p ~/Pictures/waifu2x/3x
[ -d ~/Pictures/waifu2x/4x ] || mkdir -p ~/Pictures/waifu2x/4x
[ -d ~/Pictures/waifu2x/Output ] || mkdir -p ~/Pictures/waifu2x/Output
find ~/Pictures/waifu2x -name ".DS*" -delete # Kill Desktop Services Store files so they don't confuse waifu2x
upscale 1.5;upscale 2;upscale 3;upscale 4
if [ -n "$err" ]; then
    echo "Some upscaling jobs failed." >&2
    exit "$err"
fi
RESULTS="$(ls -A ~/Pictures/waifu2x/Output/ 2>/dev/null)"
INPUT="NS"
if [ -n "$(ls -A ~/Pictures/waifu2x/*x/* 2>/dev/null)" ]; then
    while [ ! "$INPUT" = "Y" ] && [ ! "$INPUT" = "y" ] && [ ! "$INPUT" = "N" ] && [ ! "$INPUT" = "n" ] && [ ! "$INPUT" = "" ]; do
        printf "Delete original files (Y/n)? " && read -r INPUT
    done
    if [ "$INPUT" = "Y" ] || [ "$INPUT" = "y" ] || [ "$INPUT" = "" ]; then
        rm -f ~/Pictures/waifu2x/1.5x/* ~/Pictures/waifu2x/2x/* ~/Pictures/waifu2x/3x/* ~/Pictures/waifu2x/4x/*
        echo "Deleted original files"
    fi
fi
[ -n "$RESULTS" ] && echo "Finished! Check Output folder."
exit 0
