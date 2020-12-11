#!/bin/bash
#########################################################
# Stream Monitor					#
# batchanalyze.sh - Main executeable script		#
#							#
# (c) Tri Maryanto					#
# IPTV Development - MNC Play				#
# 2020 - Jakarta, Indonesia				#
#########################################################

# Read the configurations
configfile=$1
[ $# -eq 0 ] && { echo "Usage: $0 configfile"; exit 1; }
[ ! -f "$configfile" ] && { echo "Error: $0 file not found."; exit 2; }
configlines=$(sed 's/#.*//' $configfile)

tmpdir=$(grep tmpdir <<< "$configlines"|cut -d"=" -f2)
chlistfull=$(grep channellist <<< "$configlines"|cut -d"=" -f2)
mode=$(grep mode <<< "$configlines"|cut -d"=" -f2)


listcounter=1

# Initialize arrays
unset arrayurl
unset arrayname
unset arrayid
unset arrayparam

# Procedure for UDP monitoring
function udpscan {
# Read the list file
	chlist=$(echo $chlistfull|cut -d"=" -f2|rev|cut -d"/" -f1|rev)
	dos2unix -n $chlistfull $tmpdir/$chlist
	configlines=$(sed 's/#.*//' $configfile)


	maxconcur=$(grep maxconcurrent <<< "$configlines"|cut -d"=" -f2)
	listlength=$(cat $tmpdir/$chlist |wc -l)
	chlistexpanded=$tmpdir/$chlist.exp
	chunklist=$tmpdir/$chlist.chunk
	cat /dev/null > $chlistexpanded
	cat /dev/null > $chunklist

	chlist=$tmpdir/$chlist

	cellcount=$(cat $chlist|sed 's/[^,]//g' | wc -c)
	addresscount=$(( cellcount - (listlength * 2) ))

	if [ "$addresscount" -gt "$listlength" ]
	then
		for (( i=1; i<=listlength; i++ ))
		do
			thisline=$(sed -n $(echo $i)p $chlist)
			thiscellcount=$(echo $thisline|sed 's/[^,]//g' | wc -c)
			thischid=$(echo $thisline|cut -d',' -f1)
			if [ "$thiscellcount" -gt 3 ]
			then				
				thischname=$(echo $thisline|cut -d',' -f2)
				for (( j=3; j<=thiscellcount; j++ ))
				do
					thisaddress=$(echo $thisline|cut -d',' -f$j)
					profileno=$(( j - 3 ))
					echo $thischid-$profileno,$thischname,$thisaddress >> $chlistexpanded
				done
			else
				echo $thisline >> $chlistexpanded
			fi
# Delete excess XMLs
			profilescount=$(( thiscellcount - 2 ))
			./cleanmultiprofile.sh $thischid $profilescount $configfile
		done
		chlist=$chlistexpanded
		listlength=$addresscount
	fi

	if [ "$maxconcur" -gt "$listlength" ]
	then
		chunklist=$chlist
	else
		for (( i=1; i<=maxconcur; i++ ))
		do	
			sed -n $(echo $listcounter)p $chlist >> $chunklist
		 	listcounter=$(( listcounter + 1 ))
			if [ "$listcounter" -gt "$listlength" ]
			then
				listcounter=1
			fi
		done
	fi

# Start monitoring process based on maximum concurrent 
	while read p
	do
		address=`echo $p|cut -d, -f3`
		chnumber=`echo $p|cut -d, -f1`
		chname=`echo $p|cut -d, -f2`
		./analyzemcast.sh $address $chnumber "$chname" $configfile &
	done < $chunklist

	wait
	rm $chunklist
	sleep 5
}

# Procedure for HLS monitoring
function hlsscan {
# Read the list file
	chlist=$(echo $chlistfull|cut -d"=" -f2|rev|cut -d"/" -f1|rev)
	dos2unix -n $chlistfull $tmpdir/$chlist
	chlist=$tmpdir/$chlist
	listlength=$(cat $chlist |wc -l)


	while read line
	do	
		url=$(echo $line|cut -d, -f3)
		chnumber=$(echo $line|cut -d, -f1)
		chname=$(echo $line|cut -d, -f2)
		profileno="0"
		
		configlines=$(sed 's/#.*//' $configfile)
		httpretry=$(( $(grep httpretry <<< "$configlines"|cut -d"=" -f2) + 1 ))
		maxconcur=$(grep maxconcurrent <<< "$configlines"|cut -d"=" -f2)
	
		for (( i=0; i<$httpretry; i++ ))
		do
			curlres=$(curl -Ls --retry $httpretry --retry-delay 0 -w "%{http_code};%{url_effective}\n" $url)
			httpreturn=$(echo "$curlres"|tail -1|cut -d";" -f1)
			if [ "$httpreturn" = "200" ]
			then
				break
			fi
			sleep 1
		done
	
		basem3u8=$(echo "$curlres"|tail -1|cut -d";" -f2|sed -e 's/.*\///')
		baseurl=$(echo "$curlres"|tail -1|cut -d";" -f2|sed -e "s/\/*$basem3u8//")


		profilescount=$(echo "$curlres" |grep '#EXT-X-STREAM-INF' -A1 |grep -v '#EXT-X-STREAM-INF' |sort|uniq|wc -l)

		if [ "$profilescount" -gt 0 ]
		then
			while read m3u8
			do
				arrayurl+=("$baseurl/$m3u8")
				arrayname+=("$chname")
				arrayid+=("$chnumber-$profileno")
				profileno=$(( profileno + 1 ))
				profileparam=$(echo "$curlres" |grep "$m3u8" -B1 | head -1)
				arrayparam+=("$profileparam")	
			done < <(echo "$curlres" |grep '#EXT-X-STREAM-INF' -A1 |grep -v '#EXT-X-STREAM-INF' |sort|uniq)
		else
			arrayurl+=("$url")
			arrayname+=("$chname")
			arrayid+=("$chnumber")
			arrayparam+=("null")
		fi
		
# Delete excess XMLs
		./cleanmultiprofile.sh $chnumber $profilescount $configfile
			
# Start monitoring based on the maximum concurrent stream		
		while true
		do
	
			arrayurllen=${#arrayurl[@]}

			if [ "$arrayurllen" -ge "$maxconcur" ]
			then

				for (( i=0; i<$maxconcur; i++ ))
				do
					./analyzehls.sh "${arrayurl[$i]}" "${arrayid[$i]}" "${arrayname[$i]}" "${arrayparam[$i]}" $configfile &
					echo "${arrayid[$i]}","${arrayname[$i]}","${arrayurl[$i]}"
					unset 'arrayname[i]'
					unset 'arrayid[i]'
					unset 'arrayurl[i]'
					unset 'arrayparam[i]'
				done

				wait
				sleep 3
		
				j=0
				for (( i=$maxconcur; i<$arrayurllen; i++ ))
				do
					
					arrayname[$j]="${arrayname[$i]}"
					arrayid[$j]="${arrayid[$i]}"
					arrayurl[$j]="${arrayurl[$i]}"
					arrayparam[$j]="${arrayparam[$i]}"
					unset 'arrayname[i]'
					unset 'arrayid[i]'
					unset 'arrayurl[i]'
					unset 'arrayparam[i]'
					j=$(( j + 1 ))

				done
				arrayname=( "${arrayname[@]}" )
				arrayurl=( "${arrayurl[@]}" )
				arrayid=( "${arrayid[@]}" )
				arrayparam=( "${arrayparam[@]}" )

			else
				break
			fi
		done

	done < $chlist
}

# Main process. Keep iterating the monitor process based on the list file.
while :
do
	if [ "$mode" = "hls" ]
	then
		hlsscan
	else
		udpscan
	fi
done
