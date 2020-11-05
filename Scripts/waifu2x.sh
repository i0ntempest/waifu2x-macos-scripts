#!/bin/sh

#Edit this line to define a path to waifu2x.app
WAIFU2X_APP="/Applications/waifu2x.app"

if [ ! -d "${WAIFU2X_APP}" ] ; then
	echo "waifu2x.app not found" >&2;exit 1;
fi

"${WAIFU2X_APP}/Contents/MacOS/waifu2x" "$@"
