#!/bin/sh
branch=$1
tag=$2
if [ "$branch"]; then
	echo "No branch specified"
	exit
fi

if [ "$tag" == "" ]; then
	tag=( $(xcrun agvtool mvers -terse1) )
	echo "No tag specified so using current marketing version $tag"
else 
	xcrun agvtool new-marketing-version $tag
fi
#agvtool next-version -all
git commit -a -m "Create tag for version $tag"
git tag -m "Tag for $tag" -a $tag
git push origin $branch
git push --tags