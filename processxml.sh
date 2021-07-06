#!/bin/bash
#########################################################
# Stream Monitor                                        #
# processxml.sh - Called script for XML output - UDP #
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
configlines=$(sed 's/#.*//' $configfile)

maxccerror=$(grep maxaverageccerror <<< "$configlines"|cut -d"=" -f2)
tmpdir=$(grep tmpdir <<< "$configlines"|cut -d"=" -f2)
xmldir=$(grep xmldir <<< "$configlines"|cut -d"=" -f2)
logfile=$(grep logfile <<< "$configlines"|cut -d"=" -f2)
lastoutagefile=$(grep loglastoutage <<< "$configlines"|cut -d"=" -f2)
freezemode=$(grep freezedetect <<< "$configlines"|cut -d"=" -f2)
monitordur=$(grep monitorduration <<< "$configlines"|cut -d"=" -f2)
freezethreshold=$(grep freezedurationpercentage <<< "$configlines"|cut -d"=" -f2)

inputfile=$tmpdir/$chid
# Commented to fix outage detection
# [ ! -f "$inputfile" ] && { echo "Error: $0 file not found."; exit 2; }
 
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

## continuity error historical counter
oldconterror=$(cat $outputfile | grep CCERROR | sed -e 's/.*<CCERROR>//' -e 's/<\/CCERROR>.*//'| cut -d, -f2-4)
ccerrorvars=4
if [ -z "$oldconterror" ]
then
        oldconterror=0
fi

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

## get the source address
source=$(cat $inputfile|grep sources|cut -d"=" -f2)

## evaluate the informations
for disccount in "${discontinuities[@]}"
do
	totaldiscontinuities=$(( totaldiscontinuities + disccount ))
done

## CC Error average count
ccnumerator=$(echo "$totaldiscontinuities,$oldconterror" | sed -e 's/,/+/g' |bc)
ccaverage=$(( ccnumerator / ccerrorvars ))

if [ "$totalpacket" -gt 0 ]
then
	if [ "$ccaverage" -gt "$maxccerror" ]
	then
		newstat="WARNING"
	fi
else
	totalbitrate=0
	ccaverage=0
	newstat="OUTAGE"
fi

if [ "$freezemode" == "on" ]
then
	freezeduration=0
	freezepercent=0
	freezelines=$(cat $inputfile.frz|wc -l)
	if [ "$freezelines" -gt 0 ]
	then
		while read -r line
		do
			freezeduration=$(echo "scale=2; $freezeduration + $line"|bc -l)
		done < <(grep freeze_duration $inputfile.frz | cut -d"=" -f2)

		if [ "$freezeduration" == "0" ]
		then
			freezeduration="$monitordur"
		fi

		freezepercent=$(echo "scale=2; $freezeduration / $monitordur * 100"|bc -l)
	fi
	if [ "$(echo "$freezepercent"|cut -d"." -f1)" -gt "$freezethreshold" ]
	then
		newstat="WARNING"
	fi
fi


if [ "$newstat" == "$oldstat" ]
then
	newchanges=$oldchanges
else
	echo "$newchanges : $chid-$name status changed into $newstat. Source IP: $source" >> $logfile
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
echo "          <CCERROR>$oldconterror,$totaldiscontinuities</CCERROR>"
echo "          <CCAVERAGE>$ccaverage</CCAVERAGE>"
echo "          <SOURCEIP>$source</SOURCEIP>"
if [ "$freezemode" == "on" ]
then
	echo "		<FREEZEDUR>$freezeduration</FREEZEDUR>"
	echo "		<FREEZEPCT>$freezepercent</FREEZEPCT>"
else
	echo "		<FREEZEDUR>not monitored</FREEZEDUR>"
	echo "		<FREEZEPCT>not monitored</FREEZEPCT>"
fi

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
