#!/bin/bash

set -e # fail on all errors

project="b43-openfw"

function usage
{
	echo "Usage: $0 VERSION"
}

function build
{
	local dir="$1"

	if [ -z "$dir" ]; then
		echo "ERR: build missing parameter"
		exit 1
	fi

	echo "building release firmware $dir"
	mkdir -p bin/$dir
	old_dir="$PWD"
	cd $dir
	make DEBUG=0
	cp *.fw ../bin/$dir/
	make clean
	cd "$old_dir"

	echo "building debugging firmware $dir"
	mkdir -p bin-debug/$dir
	old_dir="$PWD"
	cd $dir
	make DEBUG=1
	cp *.fw ../bin-debug/$dir/
	make clean
	cd "$old_dir"
}

version=$1
if [ -z "$version" ]; then
	usage
	exit 1
fi

release_name="$project-$version"
tarball="$release_name.tar.bz2"

origin="$(pwd)"
export GIT_DIR="$origin/.git"

cd /tmp/
rm -Rf "$release_name" "$tarball"
echo "Creating target directory"
mkdir "$release_name"
cd "$release_name"
echo "git checkout"
git checkout -f

rm makerelease.sh .gitignore

build rev5

echo "creating tarball"
cd ..
tar cjf "$tarball" "$release_name"
mv "$tarball" "$origin"
rm -Rf "$release_name"

echo
echo "built release"
