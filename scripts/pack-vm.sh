#!/usr/bin/env bash

set -ex

# This are defined elsewhere (usually in travis):
# 
# ARCH		- macos32x86, linux64x64, win32x86, etc.
# SRC_ARCH	- i386, x64_86
# HEARTBEAT	- threaded, itimer (or none)

vmVersion="5.0"
productDir="../opensmalltalk-vm"
productArch=$SRC_ARCH
productHeartbeat=${HEARTBEAT}
case "${ARCH}" in
	macos32x86) 
		productDir="$productDir/build.${ARCH}/pharo.cog.spur" 
		pattern="*.app"
		os="mac"
		;;
	macos64x64) 
		productDir="$productDir/build.${ARCH}/pharo.cog.spur" 
		pattern="*.app"
		os="mac"
		;;
	linux32x86) 
		productDir="`find $productDir/products -name "${vmVersion}*"`" 
		pattern="*"
		os="linux"
		;;
	linux64x64) 
		productDir="`find $productDir/products -name "${vmVersion}*"`" 
		pattern="*"
		os="linux"
		;;
	linux32ARMv6) 
		productDir="`find $productDir/products -name "${vmVersion}*"`" 
		pattern="*"
		os="linux"
		productArch="ARMv6"
		;;
	win32x86) 
		productDir="$productDir/build.${ARCH}/pharo.cog.spur/build/vm" 
		pattern="*.exe *.dll"
		os="win"
		;;
	win64x64) 
		productDir="$productDir/build.${ARCH}/pharo.cog.spur/build/vm" 
		pattern="*.exe *.dll"
		os="win"
		;;
	*) 
		echo "Undefined platform!"
		exit 1
esac

if [ -z "${productDir}" ]; then
	echo "Error: Product not found!"
	exit 1
fi


if [[ "${APPVEYOR}" ]]; then
	commitSHA="${APPVEYOR_REPO_COMMIT}"
else
	commitSHA="${TRAVIS_COMMIT}"
fi
buildId="`echo ${commitSHA} | cut -b 1-7`"
zipFileName="`pwd`/../pharo-${os}-${productArch}${productHeartbeat}.${buildId}.zip"
pushd .
cd ${productDir}
zip -r ${zipFileName} ${pattern}
popd