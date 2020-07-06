#!/bin/bash
src=$1
dest=$2
projectname=$2
runEnv=$3
#uploadfile
if [ -d $src/lib ] && [ -d $src/conf ];then
	cd $src && tar -zcf $projectname.tar.gz conf lib
	uploadfile=$src/$projectname.tar.gz
elif [ -n "$(ls $src/*.js 2>/dev/null)" ] || [ -n "$(ls $src/*.html 2>/dev/null)" ] || [ -n "$(ls $src/*.json 2>/dev/null)" ];then
	cd $src && tar -zcf $projectname.tar.gz ./*
	uploadfile=$src/$projectname.tar.gz
elif [ -f $src ];then
	uploadfile=$src
else
	echo 'error path'
fi
echo 'cksum:'
cksum $uploadfile

echo $runEnv
if [ $runEnv = 'uat' ];then
	echo 'upload to uat'
elif [ $runEnv = 'prod' ];then
	echo 'upload to prod'
else
	mkdir -p $runEnv && scp -P 2202 -r $runEnv apps@121.201.69.220:/home/apps/beta-repository
	mkdir -p $dest && scp -P 2202 -r $dest apps@121.201.69.220:/home/apps/beta-repository/$runEnv
	scp -P 2202 $uploadfile apps@121.201.69.220:/home/apps/beta-repository/$runEnv/$dest
fi
