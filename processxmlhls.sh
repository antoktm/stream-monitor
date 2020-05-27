#!/bin/bash
#########################################################
# Stream Monitor					#
# processxmlhls.sh - Called script for XML output - HLS	#
#							#
# (c) Tri Maryanto					#
# IPTV Development - MNC Play				#
# 2020 - Jakarta, Indonesia				#
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 chid chname address configfile"; exit 1; }
## Read the parameters and config file
chid=$1
name=$2
address=$(echo $3|sed 's/\&/\&amp\;/g')
configfile=$4

expectedcont=`cat $configfile|grep mincontinuityrate|cut -d"=" -f2`
tmpdir=`cat $configfile|grep tmpdir|cut -d"=" -f2`
xmldir=`cat $configfile|grep xmldir|cut -d"=" -f2`
logfile=`cat $configfile|grep logfile|cut -d"=" -f2`
lastoutagefile=$(cat $configfile|grep loglastoutage|cut -d"=" -f2)

inputfile=$tmpdir/$chid
[ ! -f "$inputfile" ] && { echo "Error: $0 file not found."; exit 2; }
 
if [ -s "$inputfile" ] 
then
	inputfile=$tmpdir/$chid
else
	inputfile="dummyoutage"
fi

outputfile=$xmldir/$chid.xml

## capture what is the old status. copy as new status
oldstat=`cat $outputfile | grep CHSTAT | sed -e 's/.*<CHSTAT>//' -e 's/<\/CHSTAT>.*//'`
oldchanges=`cat $outputfile | grep CHLASTCHANGE | sed -e 's/.*<CHLASTCHANGE>//' -e 's/<\/CHLASTCHANGE>.*//'`

## variables initialization
totalbitrate=0
resolution=0
codecs=0
buffer=0
downloadstat=200
newstat="ONLINE"
downloadspeed=0
downloadsize=0
downloadtime=0
connecttime=0

## start reading the status file
totalbitrate=$(cat $inputfile|grep BANDWIDTH|sed -e 's/.*BANDWIDTH=//' -e 's/,.*//')
resolution=$(cat $inputfile |grep RESOLUTION|sed -e 's/.*RESOLUTION=//' -e 's/,.*//')
codecs=$(cat $inputfile|grep CODECS|sed -e 's/.*CODECS="//' -e 's/".*//')
buffer=$(cat $inputfile|grep buffer|cut -d: -f2)
downloadstat=$(cat $inputfile|grep httpcode|cut -d: -f2)
newstat=$(cat $inputfile|grep status|cut -d: -f2)
downloadspeed=$(cat $inputfile|grep avgspeed|cut -d: -f2)
downloadsize=$(cat $inputfile|grep avgsize|cut -d: -f2)
downloadtime=$(cat $inputfile|grep avgtime|cut -d: -f2)
connecttime=$(cat $inputfile|grep avgcontime|cut -d: -f2)
downloadednum=$(cat $inputfile|grep downloadedchunks|cut -d: -f2)
downloadtarget=$(cat $inputfile|grep targetchunks|cut -d: -f2)

newchanges=`date +"%F %T"`
monitored=$newchanges


## evaluate the informations

if [ "$totalbitrate" == "" ]
then
	totalbitrate=0
fi


if [ "$resolution" == "" ]
then
	resolution="undefined"
fi

if [ "$codecs" == "" ]
then
	codecs="undefined"
fi

if [ "$buffer" -gt 0 ]
then
	newstat="WARNING"
fi


if [ "$newstat" == "$oldstat" ]
then
	newchanges=$oldchanges
else
	echo "$newchanges : $chid-$name status changed into $newstat" >> $logfile
	if [ "$newstat" == "OUTAGE" ]
	then
		echo "$newchanges" > $lastoutagefile
	fi
fi


## print the informations
echo '<?xml version="1.0" encoding="UTF-8"?>'
echo "	<CHANNEL>"
echo "		<CHID>$chid</CHID>"
echo "		<CHNAME>$name</CHNAME>"
echo "		<CHSTAT>$newstat</CHSTAT>"
echo "		<CHLASTCHANGE>$newchanges</CHLASTCHANGE>"
echo "		<CHMONITORED>$monitored</CHMONITORED>"
echo "		<CHADDRESS>$address</CHADDRESS>"
echo "		<BITRATE>$totalbitrate</BITRATE>"
echo "		<CODECS>$codecs</CODECS>"
echo "		<RESOLUTION>$resolution</RESOLUTION>"
echo "		<HTTPCODE>$downloadstat</HTTPCODE>"
echo "		<BUFFER>$buffer</BUFFER>"
echo "		<CHUNKSIZE>$downloadsize</CHUNKSIZE>"
echo "		<DLSPEED>$downloadspeed</DLSPEED>"
echo "		<DLTIME>$downloadtime</DLTIME>"
echo "		<DLNUM>$downloadednum out of $downloadtarget</DLNUM>"
echo "		<CONNECTTIME>$connecttime</CONNECTTIME>"
echo "		<STREAMTYPE>HLS</STREAMTYPE>"
echo "	</CHANNEL>"
