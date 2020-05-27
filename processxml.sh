#!/bin/bash
#########################################################
# Stream Monitor                                        #
# processxmlhls.sh - Called script for XML output - UDP #
#                                                       #
# (c) Tri Maryanto                                      #
# IPTV Development - MNC Play                           #
# 2020 - Jakarta, Indonesia                             #
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 chid chname address configfile"; exit 1; }
## Read the parameters and config file
chid=$1
name=$2
address=$3
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
newstat=ONLINE
oldchanges=`cat $outputfile | grep CHLASTCHANGE | sed -e 's/.*<CHLASTCHANGE>//' -e 's/<\/CHLASTCHANGE>.*//'`

## variables initialization
totalbitrate=0
totalpacket=0
totaldiscontinuities=0

## start reading the tsduck normalized file
totalbitrate=`cat $inputfile|grep '^ts:'|sed -e 's/.*:bitrate=//' -e 's/:.*//'`
totalpacket=`cat $inputfile|grep '^ts:'|sed -e 's/.*:packets=//' -e 's/:.*//'`
newchanges=`date +"%F %T"`
monitored=$newchanges

## read list of pid and put into array
IFS=$'\r\n' GLOBIGNORE='*' command eval  'pid=($(cat $inputfile |grep "^pid:" | sed -e "s/.*:pid=//" -e "s/:.*//"))'

## read discontinuities and put into array
IFS=$'\r\n' GLOBIGNORE='*' command eval  'discontinuities=($(cat $inputfile |grep "^pid:" | sed -e "s/.*:discontinuities=//" -e "s/:.*//"))'

## read pid's bitrate and put into array
IFS=$'\r\n' GLOBIGNORE='*' command eval  'bitrate=($(cat $inputfile |grep "^pid:" | sed -e "s/.*:bitrate=//" -e "s/:.*//"))'

## read pid's description and put into array
IFS=$'\r\n' GLOBIGNORE='*' command eval  'description=($(cat $inputfile |grep "^pid:" | sed -e "s/.*:description=//" ))'

## evaluate the informations
for disccount in "${discontinuities[@]}"
do
	totaldiscontinuities=$(( totaldiscontinuities + disccount ))
done

if [ "$totalpacket" -gt 0 ]
then
	continuityrate=$(( (totalpacket - totaldiscontinuities)*100/totalpacket ))
	if [ "$continuityrate" -lt "$expectedcont" ]
	then
		newstat="WARNING"
	fi
else
	continuityrate=0
	newstat="OUTAGE"
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
echo "		<CONTRATE>$continuityrate</CONTRATE>"
echo "		<STREAMTYPE>UDP</STREAMTYPE>"
i=0
for pidnum in "${pid[@]}"
do
	echo "		<CHPID>"
	echo "			<PID>$pidnum</PID>"
	echo "			<PIDDESC>${description[i]}</PIDDESC>"
	echo "			<PIDRATE>${bitrate[i]}</PIDRATE>"
	echo "		</CHPID>"
	i=$(( i+1 ))
done
echo "	</CHANNEL>"
