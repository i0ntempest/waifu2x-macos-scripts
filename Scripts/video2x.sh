#!/usr/bin/env bash
#
# Copyright 2019-2020 Zhenfu Shi (i0ntempest)
#
# Version 0.3
#

setup_tmpdir() {
    tmpdir="/tmp/video2x_$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    mkdir -p "$tmpdir"/extracted_frames "$tmpdir"/upscaled_frames
}

get_video_info() {
    fps="$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$1" | cut -d'/' -f1)"
}

extract_frames() {
    echo "Extracting frames..."
    ffmpeg -hide_banner -i "$1" "$tmpdir"/extracted_frames/extracted_%0d.png
    if [ "$?" != 0 ]; then
        err=5;echo "Frame extraction failed" >&2;return "$err"
    fi
    total_frames=$(ls "$tmpdir"/extracted_frames | wc -l | sed 's/^ *//')
    echo "Frame extraction completed"
}

upscale() {
    if [ "$(awk -v usfactor="$4" 'BEGIN { lg = log(usfactor) / log(2); print (lg == int(lg))}')" -eq 1 ]; then
    #if (( ("$1" & ("$1" - 1)) == 0 )); then # bashism right here
            local usfactor="$4" # integer
        else
            if [ "$(awk -v usfactor="$4" 'BEGIN { print (usfactor<2) }')" -eq 1 ]; then
                local usfactor=2
                local dsfactor=$(awk "BEGIN { print $4/2*100 }") # percentage
            else
                local usfactor=4
                local dsfactor=$(awk "BEGIN { print $4/4*100 }") # percentage
            fi
        fi
        echo "$usfactor""x upscaling in progress..."
        mkdir -p "$tmpdir"/upscaled_frames/.temp
        frame_num=1
        for file in "$tmpdir"/extracted_frames/*; do
            printf "Upscaling: $frame_num/$total_frames frames\r"
            local filename="${file##*/}"; local filename="${filename%.*}"
            waifu2x --model "$2" -s "$usfactor" -n "$5" -i "$file" -o "$tmpdir"/upscaled_frames/.temp/"$filename".png > /dev/null
            if [ "$?" != 0 ]; then
                err=3;echo "Failed to upscale: $file"", frame number $frame_num" >&2;break
            fi
            ((frame_num+=1))
            #frame_num=$(expr $frame_num + 1)
        done
        if [ -n "$err" ]; then
            return "$err"
        fi
        echo ""
        echo "Upscaling finished"
        if [ -n "$dsfactor" ]; then
            echo "$dsfactor""% downscaling in progress..."
            frame_num=1
            for file in "$tmpdir"/upscaled_frames/.temp/*.png; do
                printf "Downscaling: $frame_num/$total_frames frames\r"
                local filename="${file##*/}"; local filename="${filename%.*}"
                convert "$file" -quality 1 -resize "$dsfactor"% "$tmpdir"/upscaled_frames/"$filename".png > /dev/null
                if [ "$?" != 0 ]; then
                    err=4;echo "Failed to downscale: $file"", frame number $frame_num" >&2;break
                fi
                rm "$file"
                ((frame_num+=1))
            done
            if [ -n "$err" ]; then
                return "$err"
            fi
            echo ""
            echo "Downscaling finished"
        else
            echo "No downscaling needed, moving upscaled frames in place..."
            #mv "$tmpdir"/upscaled_frames/.temp/*.png "$tmpdir"/upscaled_frames/ # fails for long videos: arg list too long
            find "$tmpdir"/upscaled_frames/.temp/ -name extracted*.png -maxdepth 1 -exec mv {} "$tmpdir"/upscaled_frames/ \;
            echo "Upscaled frames moved to assembly location"
        fi
        rm -rf "$tmpdir"/upscaled_frames/.temp
}

assemble_video() {
    echo "Assembling upscaled frames into a video..."
    assemble_dest="$tmpdir"/assembled_noaudio.mp4
    ffmpeg -hide_banner -r "$fps" -i "$tmpdir"/upscaled_frames/extracted_%d.png -preset slow -crf 15 -pix_fmt yuv420p "$assemble_dest"
    if [ "$?" != 0 ]; then
        err=5;echo "Video assembly failed" >&2;return "$err"
    fi
    echo "Assembly completed"
}

migrate_streams() {
    echo "Migrating other media streams into new video..."
    migrate_dest="$tmpdir"/migrated.mp4
    ffmpeg -hide_banner -i "$assemble_dest" -i "$1" -map 0:v:0 -map 1:a:0 -c copy "$migrate_dest"
    if [ "$?" != 0 ]; then
        err=5;echo "Stream migration failed" >&2;return "$err"
    fi
    echo "Stream migration completed"
}

cleanup() {
    if [ -d "$tmpdir" ]; then
        INPUT="NS"
        if [ "$1" = "-f" ]; then
            INPUT="N"
        else
            while [ ! "$INPUT" = "Y" ] && [ ! "$INPUT" = "y" ] && [ ! "$INPUT" = "N" ] && [ ! "$INPUT" = "n" ] && [ ! "$INPUT" = "" ]; do
                printf "Do you want to keep temporary files (y/N)? " && read -r INPUT
            done
        fi
        if [ "$INPUT" = "N" ] || [ "$INPUT" = "n" ] || [ "$INPUT" = "" ]; then
            echo "Cleaning up..."
            rm -rf "$tmpdir"
            echo "Deleted temporary files"
        fi
    fi   
}

output_video() {
    local filename="${1##*/}"; local filename="${filename%.*}"
    if [ -n "$6" ]; then
        local output_file="$6/$filename"_"$2"_"$3"_noise"$5"_"$4"x.mp4
    else
        local output_file="$(dirname "$1")/$filename"_"$2"_"$3"_noise"$5"_"$4"x.mp4
    fi
    mv "$migrate_dest" "$output_file"
    echo "Output video file: $output_file"
}

# argument parsing code taken from stack overflow
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -m|--model)
    model="$2"
    shift # past argument
    shift # past value
    ;;
    --style)
    style="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--scale-factor)
    scale_factor="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--noise-level)
    noise_level="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--input)
    input_file="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output)
    output_path="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    show_help=YES
    shift # past argument
    ;;
    -V|--version)
    show_ver=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ "$show_help" = "YES" ]; then
    printf '\e[1mVideo upscaler script based on waifu2x for macOS\e[0m\nThis script requires waifu magnifier app installed from AppStore and \"waifu2x\" command in your path.\nFree software FFmpeg is required for upscaling.\nFor scaling factors other than 2 and 4, free software ImageMagick is required.\n\nUsage:\n--model, -m <model>                 Model to run [srcnn_mps, srcnn_coreml, cunet], defaults to srcnn_mps if omitted\n--style <style>                     Style of the image [anime, photo], defaults to anime if omitted)\n--scale-factor, -s <scale-factor>   Scale factor (optional, accepts values between 1 and 4, defaults to 2 if omitted)\n--noise-level, -n <noise-level>     Noise level (optional, accepts integers from 0 to 3, defaults to 1 if omitted)\n--input, -i <input>                 Input video file\n--output, -o <output>               Output path (WITHOUT file name, defaults to the same path as input if omitted)\n--help, -h                          Show this help\n--version, -V                       Show script version\n'
    exit 0
fi
if [ "$show_ver" = "YES" ]; then
    echo "video2x script version 0.3"
    exit 0
fi
if [ -z "$input_file" ]; then
    echo "No input file specified, use -h to show usage" >&2
    exit 7
elif [ ! -f "$input_file" ]; then
    echo "Invalid input file: does not exist or is not a file >&2";exit 6
fi
if [ -n "$output_path" ] && [ ! -d "$output_path" ]; then
    echo "Invalid output path: does not exist or is not a directory >&2";exit 6
fi
if [ "$style" = "photo" ] && [ "$model" = "cunet" ]; then
    echo "CUnet model only supports anime style, exiting" >&2
    exit 8
fi
models=("srcnn_mps" "srcnn_coreml" "cunet")
if [ -z "$model" ]; then
    model=srcnn_mps
elif [[ ! ${models[*]} =~ $model ]]; then
    echo "Invalid model name, available models are: ${models[*]}" >&2
    exit 1
fi
styles=("anime" "photo")
if [ -z "$style" ]; then
    style=anime
elif [[ ! ${styles[*]} =~ $style ]]; then
    echo "Invalid style name, available styles are: ${styles[*]}" >&2
    exit 1
fi
if [ -z "$scale_factor" ]; then
    scale_factor=2
elif [ "$(awk -v usfactor="$scale_factor" 'BEGIN { print (usfactor>4||usfactor<1) }')" -eq 1 ]; then
    echo "Scaling factor is invalid or out of range, only values between 1 and 4 are supported" >&2
    exit 1
fi
if [ "$(awk -v usfactor="$scale_factor" 'BEGIN { lg = log(usfactor) / log(2); print (lg == int(lg))}')" -eq 0 ]; then
#if (( ("$1" & ("$1" - 1)) == 0 )); then # bashism right here
    if [ -z "$(which convert)" ]; then
        echo "Any scaling factors other than 2 and 4 requires 'convert' program from ImageMagick but it doesn't seem to be in your system." >&2
        exit 2
    fi
fi
noise_levels=(0 1 2 3)
if [ -z "$noise_level" ]; then
    noise_level=1
elif [[ ! ${noise_levels[*]} =~ $noise_level ]]; then
    echo "Noise level is invalid or out of range, only integers between 0 and 3 are supported" >&2
    exit 1
fi
if [ -z "$(which ffmpeg)" ]; then
    echo "This script requires FFmpeg to work but it doesn't seem to be in your system." >&2
    exit 2
fi

setup_tmpdir
get_video_info "$input_file"
extract_frames "$input_file"
if [ -n "$err" ]; then
    cleanup
    exit "$err"
fi
upscale "$tmpdir"/extracted_frames "$model" "$style" "$scale_factor" "$noise_level"
#                                  modl styl fctr nois
if [ -n "$err" ]; then
    #echo "Upscaling failed at frame number $frame_num." >&2
    cleanup
    exit "$err"
fi
assemble_video
if [ -n "$err" ]; then
    cleanup
    exit "$err"
fi
migrate_streams "$input_file"
output_video "$input_file" "$model" "$style" "$scale_factor" "$noise_level" "$output_path"
cleanup -f
