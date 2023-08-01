#!/bin/bash

# Menentukan direktori kerja skrip
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR"

TF_VERSION=2.5
URL=https://github.com/am15h/tflite_flutter_plugin/releases/download/
TAG=tf_$TF_VERSION

ANDROID_DIR=android/app/src/main/jniLibs/
ANDROID_LIB=libtensorflowlite_c.so

ARM_DELEGATE=libtensorflowlite_c_arm_delegate.so
ARM_64_DELEGATE=libtensorflowlite_c_arm64_delegate.so
ARM=libtensorflowlite_c_arm.so
ARM_64=libtensorflowlite_c_arm64.so
X86=libtensorflowlite_c_x86_delegate.so
X86_64=libtensorflowlite_c_x86_64_delegate.so

d=0

function Download {
  curl -L -o "$1" "$URL$TAG/$1"
  mkdir -p "$ANDROID_DIR$2"
  mv -f "$1" "$ANDROID_DIR$2/$ANDROID_LIB"
}

# Mengunduh file untuk arsitektur ARM
if [ $d -eq 1 ]; then
  Download "$ARM_DELEGATE" "armeabi-v7a"
  Download "$ARM_64_DELEGATE" "arm64-v8a"
else
  Download "$ARM" "armeabi-v7a"
  Download "$ARM_64" "arm64-v8a"
fi

Download "$X86" "x86"
Download "$X86_64" "x86_64"
