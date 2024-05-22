#!/usr/bin/env bash

# Assimp SDK include path on Windows (you can also clone the assimp repo and point to the include path there)
AIPATH="$PROGRAMFILES/Assimp/include"
keep_temps=false


while getopts "hki:" flag; do
	case "$flag" in
		h)
		echo "Generates an assimp header file to be imported by luajit."
		echo "flags:"
		echo "	-h: Print this message."
		echo "	-i: Indicates the assimp include path file."
		echo "	-k: Keeps temporary files created during generation."
		exit 0
		;;
		k)
		keep_temps=true
		;;
		i)
		AIPATH=$OPTARGS
		;;
		\?)
		echo "invalid flag: $flag"
		exit 1
		;;
	esac
done


# All the assimp headers we need (order matters)
includefiles=(
	"config.h"
	"defs.h"
	"vector2.h"
	"vector3.h"
	"color4.h"
	"matrix3x3.h"
	"matrix4x4.h"
	"quaternion.h"
	"types.h"
	"cfileio.h"
	"importerdesc.h"
	"aabb.h"
	"texture.h"
	"mesh.h"
	"light.h"
	"camera.h"
	"material.h"
	"anim.h"
	"metadata.h"
	"scene.h"
	"cimport.h"
	"postprocess.h"
)

: > header.h # Clean temp file

# Copy all the headers to a single file. We're basically doing the #include work here manually.
# The reason for this is because we only want to include assimp headers and ignore the system ones. 
for line in "${includefiles[@]}"; do
	cat "$AIPATH/assimp/$line" >> header.h;
done

# Remove include directives (we already included everything we need) and pragma directives (so gcc won't bitch about them when preprocessing)
sed -ri "/^#\s*(include|pragma)/d" header.h

# Preprocess our gigaheader using gcc
gcc -E -std=c99 header.h > assimp_header.h

# Get rid of some trash that may make luajit complain
sed -e "/^#\|^\s*$/d" -e "s/__attribute__((visibility(\"default\"))) //g" -e "/Force32Bit\|FORCE_32BIT\|ENFORCE_ENUM_SIZE\|ai_epsilon/d" < assimp_header.h > assimp_cdef.h

if ! $keep_temps; then
	rm header.h assimp_header.h
fi

echo "Finished generating header -> assimp_cdef.h"