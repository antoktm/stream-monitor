function moreAddress(profileNo) {
  var dotId = "dots" + profileNo;
  var textId = "more" + profileNo;
  var moreId = "moreclick" + profileNo;
  var lessId = "lessclick" + profileNo;

  var dots = document.getElementById(dotId);
  var moreText = document.getElementById(textId);
  var moreClick = document.getElementById(moreId);
  var lessClick = document.getElementById(lessId);

  if (dots.style.display === "none") {
    dots.style.display = "inline";
    moreClick.style.display = "inline"; 
    moreText.style.display = "none";
    lessClick.style.display = "none";
  } else {
    dots.style.display = "none";
    moreClick.style.display = "none"; 
    moreText.style.display = "inline";
    lessClick.style.display = "inline";
  }
}

function getUrlVars() {
    var vars = {};
    var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, function(m,key,value) {
        vars[key] = value;
    });
    return vars;
}

function getCodeDesc(httpCode) {
    var desc = "";

    switch(httpCode) {
	case "100":
		desc = "Continue";
		break;
	case "101": 
		desc = "Switching Protocols";
		break;
	case "200": 
		desc = "OK";
		break;
	case "201":
		desc = "Created";
		break;
	case "202": 
		desc = "Accepted";
		break;
	case "203":
		desc = "Non-Authoritative Information";
		break;
	case "204": 
		desc = "No Content";
		break;
	case "205": 
		desc = "Reset Content";
		break;
	case "206":
		desc = "Partial Content";
		break;
	case "300":
		desc = "Multiple Choices";
		break;
	case "301": 
		desc = "Moved Permanently";
		break;
	case "302":
		desc = "Found";
		break;
	case "303":
		desc = "See Other";
		break;
	case "304": 
		desc = "Not Modified";
		break;
	case "305": 
		desc = "Use Proxy";
		break;
	case "306":
		desc = "(Unused)";
		break;
	case "307": 
		desc = "Temporary Redirect";
		break;
	case "400": 
		desc = "Bad Request";
		break;
	case "401":
		desc = "Unauthorized";
		break;
	case "402": 
		desc = "Payment Required";
		break;
	case "403": 
		desc = "Forbidden";
		break;
	case "404": 
		desc = "Not Found";
		break;
	case "405":
		desc = "Method Not Allowed";
		break;
	case "406": 
		desc = "Not Acceptable";
		break;
	case "407": 
		desc = "Proxy Authentication Required";
		break;
	case "408": 
		desc = "Request Timeout";
		break;
	case "409": 
		desc = "Conflict";
		break;
	case "410": 
		desc = "Gone";
		break;
	case "411": 
		desc = "Length Required";
		break;
	case "412": 
		desc = "Precondition Failed";
		break;
	case "413": 
		desc = "Request Entity Too Large";
		break;
	case "414": 
		desc = "Request-URI Too Long";
		break;
	case "415": 
		desc = "Unsupported Media Type";
		break;
	case "416": 
		desc = "Requested Range Not Satisfiable";
		break;
	case "417": 
		desc = "Expectation Failed";
		break;
	case "500": 
		desc = "Internal Server Error";
		break;
	case "501": 
		desc = "Not Implemented";
		break;
	case "502": 
		desc = "Bad Gateway";
		break;
	case "503": 
		desc = "Service Unavailable";
		break;
	case "504":
 		desc = "Gateway Timeout";
		break;
	case "505": 
		desc = "HTTP Version Not Supported";
		break;
	default:
		desc = "Unknown";
    }
    return desc;
}

function getUrlParam(parameter, defaultvalue){
    var urlparameter = defaultvalue;
    if(window.location.href.indexOf(parameter) > -1){
        urlparameter = getUrlVars()[parameter];
        }
    return urlparameter;
}

function loadXMLProfile(xmlFile,profileTxt) {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = function() {
		if (this.readyState == 4 && this.status == 200) {
			populateProfile(this,profileTxt);
		}
	};
	xmlhttp.open("GET", xmlFile, true);
	xmlhttp.send();
}

function populateProfile(xml,profileTxt){
	var xmlDoc, txtAll, chStat, chChange, chBitrate, chContinuity, oneLine, pidNum, pidDesc, pidRate, chType, chCodecs, chRes, chBuffer, chHttpCode,chAddressHead,chAddressTail, dlNum, segmentSize, dlSpeed, chCCHistory, chCCAverage ;
	var chCCArr = [];
	xmlDoc = xml.responseXML;
	txtAll = "";
	oneLine = "";
	
	chType = xmlDoc.getElementsByTagName("STREAMTYPE")[0].childNodes[0].nodeValue;	

	chStat = xmlDoc.getElementsByTagName("CHSTAT")[0].childNodes[0].nodeValue;
	chChange = xmlDoc.getElementsByTagName("CHMONITORED")[0].childNodes[0].nodeValue;
	chBitrate = xmlDoc.getElementsByTagName("BITRATE")[0].childNodes[0].nodeValue;
	chAddressHead = xmlDoc.getElementsByTagName("CHADDRESS")[0].childNodes[0].nodeValue.slice(0, 58);
	chAddressTail = xmlDoc.getElementsByTagName("CHADDRESS")[0].childNodes[0].nodeValue.slice(58);
	
	if (chAddressTail == "") {
		chAddress = chAddressHead;
	}
	else
	{	
		chAddress = chAddressHead + "<span id='dots" + profileTxt + "'>...</span><a onclick='moreAddress(" + profileTxt + ")' id='moreclick" + profileTxt + "'> more</a><span id='more" + profileTxt + "' style='display:none'>" + chAddressTail + "</span><a onclick='moreAddress(" + profileTxt + ")' id='lessclick" + profileTxt + "' style='display:none'> less</a>";
	}

	

	if (chType == "HLS") {
		dlNum = xmlDoc.getElementsByTagName("DLNUM")[0].childNodes[0].nodeValue;
                segmentSize = xmlDoc.getElementsByTagName("CHUNKSIZE")[0].childNodes[0].nodeValue;
                dlSpeed = xmlDoc.getElementsByTagName("DLSPEED")[0].childNodes[0].nodeValue;
		chCodecs = xmlDoc.getElementsByTagName("CODECS")[0].childNodes[0].nodeValue;
		chRes = xmlDoc.getElementsByTagName("RESOLUTION")[0].childNodes[0].nodeValue;
		chBuffer = xmlDoc.getElementsByTagName("BUFFER")[0].childNodes[0].nodeValue;
		chHttpCode = xmlDoc.getElementsByTagName("HTTPCODE")[0].childNodes[0].nodeValue;
		
	}
	else
	{
		freezePct = xmlDoc.getElementsByTagName("FREEZEPCT")[0].childNodes[0].nodeValue;
                freezeTime = xmlDoc.getElementsByTagName("FREEZEDUR")[0].childNodes[0].nodeValue;
                chIdNum = xmlDoc.getElementsByTagName("CHID")[0].childNodes[0].nodeValue;
		chSource = xmlDoc.getElementsByTagName("SOURCEIP")[0].childNodes[0].nodeValue;
		
		pidNum = xmlDoc.getElementsByTagName("PID");
		pidDesc = xmlDoc.getElementsByTagName("PIDDESC");
		pidRate = xmlDoc.getElementsByTagName("PIDRATE");

		chCCHistory = xmlDoc.getElementsByTagName("CCERROR")[0].childNodes[0].nodeValue;
                chCCAverage = xmlDoc.getElementsByTagName("CCAVERAGE")[0].childNodes[0].nodeValue;
                chCCArr = chCCHistory.split(',');
	}

	oneLine = "<div class=\"DETAILS\">";	

	if (chStat == "ONLINE") {

		document.getElementById("profilesgrid").insertAdjacentHTML("beforeend", "<h2>Profile " + profileTxt + " : " + chAddress + "</h2>");
	}
	else {
		document.getElementById("profilesgrid").insertAdjacentHTML("beforeend", "<h2><font color=\"red\">Profile " + profileTxt + " - " + chStat + " : " + chAddress + "</font></h2>");
	}

	if (chType != "HLS") {
		oneLine += "<p><img class=\"thumbs\" src=\"thumbs/" + chIdNum + ".png\" alt=\"No Thumbnail\"></p>";
		oneLine += "<p>Bitrate: " + chBitrate + " bps</p>";
		oneLine += "<p>Source IP Address: " + chSource + "</p>";
		oneLine += "<p>CC Errors Average: " + chCCAverage + " occurrences</p>";
		oneLine += "<p>Still frames: " + freezeTime + " second(s) - "  + freezePct + "%</p>";
	}
	oneLine += "<p>Last Monitored: " + chChange + "</p>";

	if (chType == "HLS") {
		oneLine += "<table>"
		oneLine += "<tr><td>Bitrate</td><td>" + chBitrate + " bps</td></tr>";
		oneLine += "<tr><td>Resolution</td><td>" + chRes + "</td></tr>";
		oneLine += "<tr><td>Codecs</td><td>" + chCodecs + "</td></tr>";
		oneLine += "<tr><td>HTTP return</td><td>" + chHttpCode + " : " + getCodeDesc(chHttpCode) + "</td></tr>";
		oneLine += "<tr><td>Segment size</td><td>" + segmentSize + " Bytes</td></tr>";		
		oneLine += "<tr><td>Download speed</td><td>" + dlSpeed + " Bytes/s</td></tr>";
		oneLine += "<tr><td>Buffer Time</td><td>" + chBuffer + "</td></tr>";
		oneLine += "<tr><td>Downloaded segment</td><td>" + dlNum + "</td></tr>";
		oneLine += "</table>"
	}
	else {	
		oneLine += "<table><tr><td style=\"width:75%;padding:0px\">";
                var thisChartCanvas = "line-chart" + profileTxt;

		oneLine += "<table><tr><th>PID</th><th>Description</th><th>PID Rate</th></tr>"

		for (i = 0; i< pidNum.length; i++){
			var thisPidNum = pidNum[i].childNodes[0].nodeValue;
			var thisPidDesc = pidDesc[i].childNodes[0].nodeValue;
			var thisPidRate = pidRate[i].childNodes[0].nodeValue; 		
		
			oneLine +=  "<tr><td>" + thisPidNum + "</td>" + "<td>" + thisPidDesc + "</td>" + "<td>" + thisPidRate + "</td></tr>";
 		}
	
                oneLine += "</table></td><td style=\"vertical-align:center;width:25%\">"
                oneLine += "<canvas id=\"" + thisChartCanvas + "\" width=\"240\" height=\"135\"></canvas>";
                oneLine += "</td></tr></table>";
	}
	oneLine += "</div>";

	document.getElementById("profilesgrid").insertAdjacentHTML("beforeend", oneLine);

	if (chType != "HLS") {
                drawCCChart(chCCArr,chCCAverage,thisChartCanvas);
        }
}

function drawCCChart(datafillArr,ccAverage,canvasName){
        var averageArr = [];
        for (i = 0; i < datafillArr.length; i++) {
                averageArr.push(ccAverage);
        }

        new Chart(document.getElementById(canvasName), {
                type: 'line',
                data: {
                  labels: ["t-3","t-2","t-1","last"],
                  datasets: [{
                    data: datafillArr,
                    label: "CC Errors Count",
                    borderColor: "#3e95cd",
                    fill: false
                  }, {
                    data: averageArr,
                    label: "CC Errors Average",
                    borderColor: "#8e5ea2",
                    borderDash: [10,10],
                    fill: false
                  }
                ]
                },
                options: {
                  plugins: {
                    title: {
                      display: true,
                      text: 'Continuity Count Errors'
                    },
                    legend: {
                      display: false
                    }
                  },
                  maintainAspectRatio: true
                }
        });
}

function loadDetails(){
	var chTitle = decodeURI(getUrlParam('title', 'Channel Title'));
	var chChange = decodeURI(getUrlParam('change', 'No Changes'));
	var chId = decodeURI(getUrlParam('chid', 'Not Available'));
	var chProfiles = decodeURI(getUrlParam('profiles', '1'));
	var xmlFile = "";

	document.getElementById("chTitle").innerHTML = chTitle.replace(/%26/g, "&");
	
	document.getElementById("lastchange").innerHTML = "Last Changes : " + chChange;
	document.getElementById("channelid").innerHTML = "Channel Id : " + chId;
	

	if ( parseInt(chProfiles) > 1 ) {
		for (i = 0; i < parseInt(chProfiles); i++) {
			var profileTxt = i + 1;
			xmlFile = "xml/" + chId + "-" + i + ".xml";
			loadXMLProfile(xmlFile,profileTxt);
		}
	}
	else {
		xmlFile = "xml/" + chId + ".xml";
		loadXMLProfile(xmlFile,1);
	}
	
    	if ( document.getElementById("chTitleRoot").offsetHeight < document.getElementById("chTitle").scrollHeight ) {
       		document.getElementById("chTitleRoot").classList.toggle('headermarquee');
    	}

}
