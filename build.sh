#!/bin/bash
 
upload=0
tweet=""
 
while getopts ":t:up:w:" Option
do
  case $Option in
    w ) tweet=$OPTARG;;
    u ) upload=1;;
    p ) project=$OPTARG;;
    t ) tag=$OPTARG;;
  esac
done
shift $(($OPTIND - 1))
 
if [ "$project" == "" ]; then
	echo "No project specified"
	exit
fi
 
if [ "$tag" == "" ]; then
	echo "No tag specified"
	exit
fi
 
# Configuration
#devired_data_path="$HOME/Library/Developer/Xcode/DerivedData"
final_builds=~/Dev/release_builds
code_folder=~/Dev/$project
build_folder=$code_folder/build
keys_folder=~/Development/keys
upload_destination=user@yourcompany.com:/usr/local/apache2/htdocs/downloads/
release_notes_webfolder=http://yourcompany.com/releasenotes
downloads_webfolder=http://yourcompany.com/downloads
twitter_uname=someone@somewhere.com
twitter_pword=password
 
if [ ! -d  $final_builds ]; then
	mkdir $final_builds
fi
 
# clean up
if [ -d $build_folder ]; then
	rm -rf $build_folder
fi
 
cd $code_folder
 
git pull origin master
git pull --tags
git checkout $tag
 
sed -i "" 's/__VERSION__/'$tag'/g' Info.plist
 
echo building project
xcodebuild -target $project -configuration Release OBJROOT=$build_folder SYMROOT=$build_folder OTHER_CFLAGS=""
 
if [ $? != 0 ]; then
	echo "Bad build for $project"
	say "bad build!"
else
 
	#ok, let's index the documentation if we've got it.
	#/Developer/Applications/Utilities/Help\ Indexer.app/Contents/MacOS/Help\ Indexer "/tmp/buildapp/build/Release/BuildApp.app/Contents/Resources/English.lproj/BuildAppHelp"
 
	mv $build_folder/Release/$project.app $final_builds
 
	# make the zip file
	cd $final_builds
	zip -r $project-$tag.zip $project.app
 
	rm -rf $project.app
 
	if [ $upload == 1 ]; then
 
		echo uploading to server...
		# upload
		scp $project-$tag.zip $upload_destination
 
		# get values for appcast
		dsasignature=`$keys_folder/sign_update.rb $final_builds/$project-$tag.zip $keys_folder/$project\_dsa_priv.pem`
		filesize=`stat -f %z $final_builds/$project-$tag.zip`
		pubdate=`date "+%a, %d %h %Y %T %z"`
 
		cd $code_folder
 
		cfbundleversion=`agvtool what-version -terse`
 
		#output appcast item
		echo
		echo Put the following text in your appcast
		echo "<item>"
		echo "<title>Version $tag</title>"
		echo "<sparkle:releaseNotesLink>"
		echo "$release_notes_webfolder/$project.html"
		echo "</sparkle:releaseNotesLink>"
		echo "<pubDate>$pubdate</pubDate>"
		echo "<enclosure url=\"$downloads_webfolder/$project-$tag.zip\""
		echo "sparkle:version=\"$cfbundleversion\""
		echo "sparkle:shortVersionString=\"$tag\""
		echo "sparkle:dsaSignature=\"$dsasignature\""
		echo "length=\"$filesize\""
		echo "type=\"application/octet-stream\" />"
		echo "</item>"
		if [ "$tweet" != "" ]; then
			echo "Calling twitter: $tweet"
			curl -u $twitter_uname:$twitter_pword -d status="$project $tag is up. $tweet" http://twitter.com/statuses/update.xml
		fi
	fi
 
	open $final_builds
	say "done building"
 
fi
 
cd $code_folder
git checkout Info.plist
rm -rf $build_folder