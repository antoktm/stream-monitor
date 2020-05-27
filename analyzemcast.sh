#!/bin/bash
#########################################################
# Stream Monitor					#
# analyzemcast.sh - Called script for UDP monitoring	#
#							#
# (c) Tri Maryanto					#
# IPTV Development - MNC Play				#
# 2020 - Jakarta, Indonesia				#
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 address chid chname configfile"; exit 1; }
# Read the parameters and configuration file
address=$1
chid=$2
chname=$3
configfile=$4

inputeth=`cat $configfile|grep interface|cut -d"=" -f2`
inputip=`ip -o -4 addr list $inputeth | awk '{print $4}' | cut -d"/" -f1`
duration=`cat $configfile|grep monitorduration|cut -d"=" -f2`
expectedcont=`cat $configfile|grep mincontinuityrate|cut -d"=" -f2`
timeout=`cat $configfile|grep igmptimeout|cut -d"=" -f2`

tmpdir=`cat $configfile|grep tmpdir|cut -d"=" -f2`
xmldir=`cat $configfile|grep xmldir|cut -d"=" -f2`

if [[ $chid =~ "-" ]]
then
	chidbase=$(printf %03d $(echo $chid|cut -d'-' -f1))
	chidnorm=$(echo $chidbase-$(echo $chid|cut -d'-' -f2))
else
	chidnorm=$(printf %03d $chid)
	chidbase=$chidnorm
fi

save=$tmpdir/$chidnorm
savexml=$xmldir/$chidnorm.xml
savexmlbase=$xmldir/$chidbase.xml
savexmltmp=$tmpdir/$chidnorm.xml.tmp

# TSDuck command for UDP probing
tsp -I ip --receive-timeout $timeout -l $inputip $address -P analyze --normalize -o $save  -P until -s $duration -O drop

# Reformat the output into xml
./processxml.sh $chidnorm "$chname" $address $configfile > $savexmltmp

if [ "$savexmlbase" = "$savexml" ]
then
	rm $xmldir/$chidbase*
fi

rm $savexmlbase
mv $savexmltmp $savexml
rm $save
