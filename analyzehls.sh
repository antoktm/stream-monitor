#!/bin/bash
#########################################################
# Stream Monitor					#
# analyzehls.sh - Called script for HLS monitoring	#
#							#
# (c) Tri Maryanto					#
# IPTV Development - MNC Play				#
# 2020 - Jakarta, Indonesia				#
#########################################################

[ $# -eq 0 ] && { echo "Usage: $0 address chid chname configfile"; exit 1; }

# Read the parameters and config file
address=$1
chid=$2
chname=$3
chparam=$4
configfile=$5


duration=`cat $configfile|grep monitoredsegment|cut -d"=" -f2`
expectedcont=`cat $configfile|grep mincontinuityrate|cut -d"=" -f2`
timeout=`cat $configfile|grep httptimeout|cut -d"=" -f2`
tolerance=$(cat "$configfile"|grep updatetolerance|cut -d"=" -f2)
tolerancesec=$(echo "$tolerance"|cut -d"." -f1)
tolerancemsc=$(echo "$tolerance"|cut -d"." -f2)
httpretry=$(( $(cat "$configfile"|grep httpretry|cut -d"=" -f2) + 1 ))


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

# Get the m3u8
for (( i=0; i<$httpretry; i++ ))
do
	curlres=$(curl -Ls --connect-timeout $timeout --retry $httpretry --retry-delay 0 -w "%{http_code};%{url_effective}\n" $address)
	httpreturn=$(echo "$curlres"|tail -1|cut -d";" -f1)
	if [ "$httpreturn" = "200" ]
        then
        	break
        fi
	sleep 1
done

basem3u8=$(echo "$curlres"|tail -1|cut -d";" -f2|sed -e 's/.*\///')
baseurl=$(echo "$curlres"|tail -1|cut -d";" -f2|sed -e "s/\/*$basem3u8//")


# Download and process the segmented TS file
echo $chparam > $save
chunksparam=$(curl --connect-timeout $timeout -Ls $address|grep '#EXTINF' -A1|tail -2)
buffertime=0
totalsize=0
totalspeed=0
totaltime=0
totalconnect=0
downloadedchunks=0
chstatus="offline"
for (( i=0; i<$duration; i++ ))
do
	chunkduration=$(echo "$chunksparam"|head -1|cut -d ':' -f2| cut -d ',' -f1|cut -d '.' -f1)
	chunkfile=$(echo "$chunksparam"|tail -1)

	sleep $(( $chunkduration + $tolerancesec )).$tolerancemsc &

	echo donloding : $baseurl/$chunkfile

	start_time="$(date -u +%s)"
	for (( j=0; j<$httpretry; j++ ))
	do
		curlfullcmdres=$(curl --connect-timeout $timeout --retry $httpretry --retry-delay 0 --write-out "%{http_code};%{size_download};%{speed_download};%{time_connect};%{time_total}\n" -Ls -o /dev/null $baseurl/$chunkfile)
		curlresult=$(echo $curlfullcmdres|cut -d';' -f1)
		if [ "$curlresult" = "200" ]
		then 
			break
		fi
		sleep $tolerancesec.$tolerancemsc
	done
	end_time="$(date -u +%s)"
	
	curlfullcmdres=$(echo $curlfullcmdres|sed 's/,/./g')
		
	totalsize=$(echo "$totalsize+$(echo $curlfullcmdres|cut -d';' -f2)"| bc -l)
	totalspeed=$(echo "$totalspeed+$(echo $curlfullcmdres|cut -d';' -f3)"| bc -l)
	totaltime=$(echo "$totaltime+$(echo $curlfullcmdres|cut -d';' -f5)"|bc -l)
	totalconnect=$(echo "$totalconnect+$(echo $curlfullcmdres|cut -d';' -f4)"|bc -l)
	
	elapsed="$(($end_time-$start_time))"

	if [ "$elapsed" -gt "$chunkduration" ]
	then
		buffertime=$(( $buffertime + $elapsed ))
	fi

	wait

	nextchunksparam=$(curl --connect-timeout $timeout --retry $httpretry --retry-delay 0 -Ls $address|grep '#EXTINF' -A1|tail -2)

	if [ "$nextchunksparam" = "$chunksparam" ] || [ "$curlresult" != "200" ]
	then
		chstatus="OUTAGE"
		if [ "$curlresult" = "200" ]
		then
			downloadedchunks=$(( i+1 ))
		fi
		break
	else
		chstatus="ONLINE"
		downloadedchunks=$(( i+1 ))
		chunksparam="$nextchunksparam"
	fi
done

# output to text file
echo "status:$chstatus" >> $save
echo "buffer:$buffertime" >> $save
echo "httpcode:$curlresult" >> $save
echo "avgspeed:$(echo "scale=2; $totalspeed/$duration"|bc -l)" >> $save
echo "avgtime:$(echo "scale=2; $totaltime/$duration"|bc -l)" >> $save
echo "avgsize:$(echo "scale=2; $totalsize/$duration"|bc -l)" >> $save
echo "avgcontime:$(echo "scale=4; $totalconnect/$duration"|bc -l)" >> $save
echo "downloadedchunks:$downloadedchunks" >> $save
echo "targetchunks:$duration" >> $save

# Reformat the output into XML
./processxmlhls.sh $chidnorm "$chname" $address $configfile > $savexmltmp

if [ "$savexmlbase" = "$savexml" ]
then
	rm $xmldir/$chidbase*
fi

rm $savexmlbase
mv $savexmltmp $savexml
rm $save
