#!/bin/bash
#########################################################
# Stream Monitor                                        #
# compiledata.sh - Executable script for data compiler  #
#                                                       #
# (c) Tri Maryanto                                      #
# IPTV Development - MNC Play                           #
# 2020 - Jakarta, Indonesia                             #
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 configfile"; exit 1; }
# Read the parameters and config file
configfile=$1

tmpdir=`cat $configfile|grep tmpdir|cut -d"=" -f2`
xmldir=`cat $configfile|grep xmldir|cut -d"=" -f2`
logfile=`cat $configfile|grep logfile|cut -d"=" -f2`
listfile=$(cat $configfile|grep channellist|cut -d"=" -f2)
logshown=$(cat $configfile|grep logshownlines|cut -d"=" -f2)
logrotate=$(cat $configfile|grep logrotate|cut -d"=" -f2)
lastoutagefile=$(cat $configfile|grep loglastoutage|cut -d"=" -f2)
mode=$(cat $configfile|grep mode|cut -d"=" -f2)
nodename=$(cat $configfile|grep nodename|cut -d"=" -f2)

statusxml=$(cat $configfile|grep statusfile|cut -d"=" -f2)
compiledxml=$(cat $configfile|grep compiledxml|cut -d"=" -f2)

statxmltmp=$tmpdir/statxml.tmp
compxmltmp=$tmpdir/compxml.tmp

countonline=0
countoutage=0
countwarning=0

echo '<?xml version="1.0" encoding="UTF-8"?>' > $compxmltmp
echo '<CHLIST>' >> $compxmltmp
echo '	<MODE>'$mode'</MODE>' >> $compxmltmp
# Start reading the XMLs and compile the summary
while read line
do
	chid=$(echo $line|cut -d, -f1)
	chidnorm=$(printf %03d $chid)
	chprofilecount=$(ls $xmldir/$chidnorm*.xml | wc -l)
	echo "	<CHANNEL>" >> $compxmltmp
	if [ "$chprofilecount" -gt 1 ]
	then
		echo "		<CHID>"$chidnorm"</CHID>" >> $compxmltmp
		grep CHNAME $xmldir/$chidnorm-0.xml >> $compxmltmp
		chstat=$(grep CHSTAT $xmldir/$chidnorm-0.xml | sed -e 's/.*<CHSTAT>//' -e 's/<\/CHSTAT>.*//')
		chlastchange=$(grep CHLASTCHANGE $xmldir/$chidnorm-0.xml | sed -e 's/.*<CHLASTCHANGE>//' -e 's/<\/CHLASTCHANGE>.*//')
		chbitrate=$(grep BITRATE $xmldir/$chidnorm-0.xml | sed -e 's/.*<BITRATE>//' -e 's/<\/BITRATE>.*//')
		if [ "$mode" = "hls" ]
		then
			chbuffer=$(grep BUFFER $xmldir/$chidnorm-0.xml | sed -e 's/.*<BUFFER>//' -e 's/<\/BUFFER>.*//')
		else
			chcontrate=$(grep CONTRATE $xmldir/$chidnorm-0.xml | sed -e 's/.*<CONTRATE>//' -e 's/<\/CONTRATE>.*//')
		fi

		for (( i=1; i<chprofilecount; i++ ))
		do
			thischstat=$(grep CHSTAT $xmldir/$chidnorm-$i.xml | sed -e 's/.*<CHSTAT>//' -e 's/<\/CHSTAT>.*//')
			if [ "$chstat" != "$thischstat" ]
			then
				chstat="WARNING"
			fi

			chchangeinsec=$(date -d "$chlastchange" +%s)
			thischlastchange=$(grep CHLASTCHANGE $xmldir/$chidnorm-$i.xml | sed -e 's/.*<CHLASTCHANGE>//' -e 's/<\/CHLASTCHANGE>.*//')
			thischchangeinsec=$(date -d "$thischlastchange" +%s)
			if [ "$thischchangeinsec" -gt "$chchangeinsec" ]
			then
				chlastchange=$thischlastchange
			fi

			thischbitrate=$(grep BITRATE $xmldir/$chidnorm-$i.xml | sed -e 's/.*<BITRATE>//' -e 's/<\/BITRATE>.*//')
			chbitrate=$(( chbitrate + thischbitrate ))
			if [ "$mode" = "hls" ]
                	then
				thischbuffer=$(grep BUFFER $xmldir/$chidnorm-$i.xml | sed -e 's/.*<BUFFER>//' -e 's/<\/BUFFER>.*//')
				if [ "$thischbuffer" -gt "$chbuffer" ]
				then
					chbuffer=$thischbuffer
				fi
			else
				thischcontrate=$(grep CONTRATE $xmldir/$chidnorm-$i.xml | sed -e 's/.*<CONTRATE>//' -e 's/<\/CONTRATE>.*//')
				chcontrate=$(( ( (chcontrate * i) + thischcontrate ) / ( i + 1 ) ))
			fi
		done
		
		echo "		<CHSTAT>"$chstat"</CHSTAT>" >> $compxmltmp
		echo "		<CHLASTCHANGE>"$chlastchange"</CHLASTCHANGE>" >> $compxmltmp
		echo "		<BITRATE>"$chbitrate"</BITRATE>" >> $compxmltmp
		if [ "$mode" = "hls" ]
                then
			echo "		<BUFFER>"$chbuffer"</BUFFER>" >> $compxmltmp
		else
			echo "		<CONTRATE>"$chcontrate"</CONTRATE>" >> $compxmltmp
		fi
		echo "		<PROFILECOUNT>"$(( chprofilecount - 1 ))"</PROFILECOUNT>" >> $compxmltmp
	else
		if [ -f "$xmldir"/"$chidnorm".xml ]
		then
			chstat=$(grep CHSTAT $xmldir/$chidnorm.xml | sed -e 's/.*<CHSTAT>//' -e 's/<\/CHSTAT>.*//')
			if [ "$mode" = "hls" ]
                	then
				egrep "CHID|CHNAME|CHSTAT|CHLASTCHANGE|BITRATE|BUFFER" $xmldir/$chidnorm.xml >> $compxmltmp
			else
				egrep "CHID|CHNAME|CHSTAT|CHLASTCHANGE|BITRATE|CONTRATE" $xmldir/$chidnorm.xml >> $compxmltmp
			fi
		else
			chstat=$(grep CHSTAT $xmldir/dummy.xml | sed -e 's/.*<CHSTAT>//' -e 's/<\/CHSTAT>.*//')
			chname=$(echo $line|cut -d, -f2)
			echo "		<CHID>$chid</CHID>" >> $compxmltmp
			echo "		<CHNAME>$chname</CHNAME>" >> $compxmltmp
			if [ "$mode" = "hls" ]
                	then
				egrep "CHSTAT|CHLASTCHANGE|BITRATE|BUFFER" $xmldir/dummy.xml >> $compxmltmp
			else
				egrep "CHSTAT|CHLASTCHANGE|BITRATE|CONTRATE" $xmldir/dummy.xml >> $compxmltmp
			fi
		fi

		echo "		<PROFILECOUNT>0</PROFILECOUNT>" >> $compxmltmp
	fi
	
	case "$chstat" in
		OUTAGE)
			countoutage=$(( countoutage + 1 ))
			;;

		ONLINE)
			countonline=$(( countonline + 1 ))
			;;

		*)
			countwarning=$(( countwarning + 1 ))
			;;

	esac

	echo " 	</CHANNEL>" >> $compxmltmp
done < $listfile

echo '</CHLIST>' >> $compxmltmp

# Create the node monitoring status file
monitortime=$(date -r $xmldir/$(ls -Art $xmldir|tail -n1) +"%F %T")
monitortimesecs=$(date -d "$monitortime" +%s)
uptime=$(uptime -p)
logcount=$(wc -l $logfile*|tail -1|cut -d" " -f1,3)
logsize=$(du -ch $logfile*|grep total|cut -f1)
lastlogsecs=$(date -d "$(tail -1 $logfile |cut -d' ' -f1,2)" +%s)
lastlogdiff=$(( monitortimesecs - lastlogsecs ))

echo '<?xml version="1.0" encoding="UTF-8"?>' > $statxmltmp
echo '<SERVICE>' >> $statxmltmp
echo '	<NODEID>'$nodename'</NODEID>' >> $statxmltmp
echo '	<TIME>'$monitortime'</TIME>' >> $statxmltmp
echo '	<OFFLINE>'$countoutage'</OFFLINE>' >> $statxmltmp
echo '	<ONLINE>'$countonline'</ONLINE>' >> $statxmltmp
echo '	<WARNING>'$countwarning'</WARNING>' >> $statxmltmp
echo '	<TOTAL>'$(( countoutage + countonline + countwarning ))'</TOTAL>' >> $statxmltmp
echo '	<LASTSTAT>'$(eval echo $(date -ud "@$lastlogdiff" +'$(( %s/3600/24 )) days %H hours %M minutes %S seconds'))'</LASTSTAT>' >> $statxmltmp
echo '	<UPTIME>'$uptime'</UPTIME>' >> $statxmltmp
echo '	<LOGCOUNT>'$logcount'</LOGCOUNT>' >> $statxmltmp
echo '	<LOGSIZE>'$logsize'</LOGSIZE>' >> $statxmltmp
echo '	<LASTERROR>'$(cat $lastoutagefile)'</LASTERROR>' >> $statxmltmp
echo '	<CHANGELIST>' >> $statxmltmp
# process the log shown
thislogcount=$(wc -l $logfile|cut -d" " -f1)
if [ "$logshown" -gt "$thislogcount" ]
then
	logdiff=$(( logshown - thislogcount ))
	while read logline
	do
		echo '		<CHANGEITEM>'$logline'</CHANGEITEM>' >> $statxmltmp
	done < <(tail -$logdiff $logfile.0)
fi
while read logline
do
	echo '		<CHANGEITEM>'$logline'</CHANGEITEM>' >> $statxmltmp
done < <(tail -$logshown $logfile)
echo '	</CHANGELIST>' >> $statxmltmp
echo '</SERVICE>' >> $statxmltmp

cp $statxmltmp $statusxml
cp $compxmltmp $compiledxml

# rotate the logfile
if [ "$thislogcount" -gt "$logrotate" ]
then 
	savelog -t -n -c 10 $logfile
fi
