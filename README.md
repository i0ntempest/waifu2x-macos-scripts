# waifu2x-macos-scripts
[![](https://img.shields.io/github/license/i0ntempest/waifu2x-macos-scripts.svg)](https://github.com/imxieyi/waifu2x-ios/blob/master/LICENSE)
## Introduction

This is the repository where I put my shell scripts that utilizes the CLI interface of [waifu2x on macOS (waifu magifier)](https://github.com/imxieyi/waifu2x-ios). 

## Why do you make these?

Most waifu2x upscalers are either Windows only, or lacks some features I want. So I created these, mostly as scripting practices.

## Scripts
- [waifu2x.sh](./Scripts/waifu2x.sh)

    POSIX sh script. Simple launcher script that passes all args to the executable. Nothing fancy here. Also featured in [waifu2x-ios wiki](https://github.com/imxieyi/waifu2x-ios/wiki/Usage-for-Command-Line-\(CLI\)-on-macOS-Version). You need to grant the app file access permission in its GUI before using this. All scripts below depend on this being in your PATH as `waifu2x`.

- [auto-waifu2x.sh](./Scripts/auto-waifu2x.sh)

    POSIX sh script. Assumes you have a certain folder structure under `~/Pictures/` (if not it will create it for you), and does multiple upscaling jobs with different scaling factors with one single command. The `upscale()` function supports arbitrary factor upscaling (accepts anything from 1 to 4 rather than just 2, 3, and 4, requires [ImageMagick](https://imagemagick.org)).

- [auto-waifu2x-moveimg.sh](./Scripts/auto-waifu2x-moveimg.sh)

    POSIX sh script. Assumes the same folder structure as above, scans a given folder for images and move them into appropriate folder based on their size, for upscaling later. Edit `master_res_width` variable to set your desired target resolution (3840 by default). Requires [ImageMagick](https://imagemagick.org).

- [video2x.sh](./Scripts/video2x.sh)

    Bash script. Basic video upscaler script, resembles early versions of [video2x](https://video2x.org). Should be able to take any video as an input, but output is currently hardcoded to be H.264 mp4. Requires [FFmpeg](https://ffmpeg.org), arbitrary factor upscaling requires [ImageMagick](https://imagemagick.org).

- More to be added

## Contributing
Ideas and PRs are welcomed.
