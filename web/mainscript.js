function readMore() {
  var moreText = document.getElementById("more");
  var btnText = document.getElementById("moreBtn");
  if (moreText.style.display === "inline") {
    btnText.innerHTML = "Show Latest Log"; 
    moreText.style.display = "none";
  } else {
    btnText.innerHTML = "Hide Latest Log"; 
    moreText.style.display = "inline";
  }
}

function CopyToClipboard(containerid) {
	var range = document.createRange();	
	var infoText = document.getElementById(containerid);
	infoText.style.visibility = "visible";
    range.selectNode(document.getElementById(containerid));
    window.getSelection().removeAllRanges(); // clear current selection
    window.getSelection().addRange(range); // to select text
    document.execCommand("copy");
    window.getSelection().removeAllRanges();// to deselect
	infoText.style.visibility = "hidden";
}

function loadXMLStat() {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = function() {
		if (this.readyState == 4 && this.status == 200) {
			populateStat(this);
		}
	};
	xmlhttp.open("GET", "servicestat.xml", true);
	xmlhttp.send();
}

function populateStat(xml){
	var x, xmlDoc, txt, statusTxt, lastChangeTxt, nodeId;
	xmlDoc = xml.responseXML;
	txt = "";
	
	nodeId = xmlDoc.getElementsByTagName("NODEID")[0].childNodes[0].nodeValue;
	
	statusPlainTxt= "ONLINE: " + xmlDoc.getElementsByTagName("ONLINE")[0].childNodes[0].nodeValue + " WARNING: " + xmlDoc.getElementsByTagName("WARNING")[0].childNodes[0].nodeValue + " OFFLINE: " + xmlDoc.getElementsByTagName("OFFLINE")[0].childNodes[0].nodeValue  +  " TOTAL: " + xmlDoc.getElementsByTagName("TOTAL")[0].childNodes[0].nodeValue;	
	
	statusTxt = "<span style='color:green'> ONLINE: " + xmlDoc.getElementsByTagName("ONLINE")[0].childNodes[0].nodeValue + "</span><span style='color:orange'> WARNING: " + xmlDoc.getElementsByTagName("WARNING")[0].childNodes[0].nodeValue + "</span> OFFLINE: " + xmlDoc.getElementsByTagName("OFFLINE")[0].childNodes[0].nodeValue  +  " <span style='color:blue'>TOTAL: " + xmlDoc.getElementsByTagName("TOTAL")[0].childNodes[0].nodeValue + "</span>";
	
	lastChangeTxt = "Last status change: " + xmlDoc.getElementsByTagName("LASTSTAT")[0].childNodes[0].nodeValue;
	
	
	document.getElementById("gentime").innerHTML = xmlDoc.getElementsByTagName("TIME")[0].childNodes[0].nodeValue;
	document.getElementById("uptime").innerHTML = "System has been " + xmlDoc.getElementsByTagName("UPTIME")[0].childNodes[0].nodeValue;
	document.getElementById("lastchange").innerHTML = lastChangeTxt;
	document.getElementById("status").innerHTML = statusTxt;
	document.getElementById("changelog").innerHTML = "Change <a href=./log/?C=M;O=D>log</a>: " + xmlDoc.getElementsByTagName("LOGCOUNT")[0].childNodes[0].nodeValue + " files, " + xmlDoc.getElementsByTagName("LOGSIZE")[0].childNodes[0].nodeValue + " bytes total";

	document.getElementById("pagetitle").innerHTML = "<h1>" + nodeId + "</h1>";
	
	document.getElementById("infoPaste").innerHTML = `*${nodeId}*  
${statusPlainTxt}
${lastChangeTxt}`;
	
	x = xmlDoc.getElementsByTagName("CHANGEITEM");
	for (i = 0; i< x.length; i++){
		txt += x[i].childNodes[0].nodeValue + "<br>";
	}
	document.getElementById("more").innerHTML = txt;
}

function loadXMLList() {
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = function() {
		if (this.readyState == 4 && this.status == 200) {
			populateList(this);
		}
	};
	xmlhttp.open("GET", "chstat.xml", true);
	xmlhttp.send();
}

function populateList(xml){
	var xmlDoc, txtAll, txtOff, chName, chStat, chChange, oneLine, chId, monitorMode, uri;
	xmlDoc = xml.responseXML;
	txtAll = "";
	txtOff = "";
	oneLine = "";

	monitorMode = xmlDoc.getElementsByTagName("MODE")[0].childNodes[0].nodeValue;
	
	chName = xmlDoc.getElementsByTagName("CHNAME");
	chId = xmlDoc.getElementsByTagName("CHID");
	chStat = xmlDoc.getElementsByTagName("CHSTAT");
	chChange = xmlDoc.getElementsByTagName("CHLASTCHANGE");
	chProfCount = xmlDoc.getElementsByTagName("PROFILECOUNT");
	chBitrate = xmlDoc.getElementsByTagName("BITRATE");
	if (monitorMode == "hls" ) {
		chBuffer = xmlDoc.getElementsByTagName("BUFFER");
	}
	else {
		chContinuity = xmlDoc.getElementsByTagName("CCAVERAGE");
	}
	
	for (i = 0; i< chName.length; i++){
		var thisProfileCount = parseInt(chProfCount[i].childNodes[0].nodeValue) + 1; 	
		var thisMbps = parseFloat(chBitrate[i].childNodes[0].nodeValue) / 1000000;
		var thisChName = encodeURI(chName[i].childNodes[0].nodeValue);
		var thisChange = encodeURI(chChange[i].childNodes[0].nodeValue);
		var thisChId = encodeURI(chId[i].childNodes[0].nodeValue); 		
		
		if (chStat[i].childNodes[0].nodeValue == "OUTAGE") {
			oneLine = "<div class=\"OFFLIN\"";
		}
		else if (chStat[i].childNodes[0].nodeValue == "WARNING") {
			oneLine = "<div class=\"WARNIN\"";
		}
		else {
			oneLine = "<div class=\"ONLIN\"";			
		}
		
		uri = "title=" + thisChName.replace(/&/g, "%26") + "&change=" + thisChange + "&chid=" + thisChId + "&profiles=" + thisProfileCount;
		

		if (monitorMode == "hls" ) {
			oneLine +=  " onClick=\"popupCenter({url: 'details.html?" + uri + "', title: 'Channel Details', w: 900, h: 500})\"><h2>" + chName[i].childNodes[0].nodeValue + "</h2><p>" + thisProfileCount + " profile(s)</br>" + chBuffer[i].childNodes[0].nodeValue + " sec(s) buffering</br>" + thisMbps.toFixed(2) + " Mbps</p></div>";
		}
		else {
			oneLine +=  " onClick=\"popupCenter({url: 'details.html?" + uri + "', title: 'Channel Details', w: 900, h: 500})\"><h2>" + chName[i].childNodes[0].nodeValue + "</h2><p>" + thisProfileCount + " profile(s)</br>" + "CC Errors : " + chContinuity[i].childNodes[0].nodeValue + "</br>" + thisMbps.toFixed(2) + " Mbps</p></div>";
		}
		
 		txtAll += oneLine;

		if (chStat[i].childNodes[0].nodeValue != "ONLINE") {
			txtOff += oneLine;
		}

	}
	document.getElementById("offlinegrid").innerHTML = txtOff;
	document.getElementById("allgrid").innerHTML = txtAll;
}

const popupCenter = ({url, title, w, h}) => {
    // Fixes dual-screen position                             Most browsers      Firefox
    const dualScreenLeft = window.screenLeft !==  undefined ? window.screenLeft : window.screenX;
    const dualScreenTop = window.screenTop !==  undefined   ? window.screenTop  : window.screenY;

    const width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width;
    const height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height;

    const systemZoom = width / window.screen.availWidth;
    const left = (width - w) / 2 / systemZoom + dualScreenLeft
    const top = (height - h) / 2 / systemZoom + dualScreenTop
    const newWindow = window.open(url, title, 
      `
      scrollbars=yes,
      width=${w / systemZoom}, 
      height=${h / systemZoom}, 
      top=${top}, 
      left=${left}
      `
    )

    if (window.focus) newWindow.focus();
}

function loadAllXml(){
	loadXMLStat();
	loadXMLList();
}
