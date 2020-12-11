#!/bin/bash
#########################################################
# Stream Monitor                                        #
# cleanmultiprofile.sh - Clean XMLs if profile number   #
# reduced.												#
#                                                       #
# (c) Tri Maryanto                                      #
# IPTV Development - MNC Play                           #
# 2020 - Jakarta, Indonesia                             #
#########################################################

[ $# -lt 3 ] && { echo "Usage: $0 chid profilecount configfile"; exit 1; }

# Read the parameters and config file
chid=$1
profilecount=$2
configfile=$3
configlines=$(sed 's/#.*//' $configfile)
xmldir=$(grep xmldir <<< "$configlines"|cut -d"=" -f2)
chidnorm=$(printf %03d $chid)
xmlcount=$(ls $xmldir/$chidnorm*.xml | wc -l)

# Delete excess XML files
if [ "$xmlcount" -gt "$profilecount" ]
then
	for (( i=0; i<profilecount; i++ ))
	do
		cp $xmldir/$chidnorm-$i.xml $xmldir/$chidnorm-$i.bak
	done
	
	rm $xmldir/$chidnorm*.xml
	
	for (( i=0; i<profilecount; i++ ))
	do
		mv $xmldir/$chidnorm-$i.bak $xmldir/$chidnorm-$i.xml
	done
fi