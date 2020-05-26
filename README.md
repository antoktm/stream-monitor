# stream-monitor
Linux-based IP video stream monitoring framework

## What is this ?
A set of shell scripts to monitor linear video streams in the form of UDP multicast or HTTP Live Streaming (HLS). The script will read the list of stream from a plain-text file and test it in round-robin manner. 

The UDP monitoring engine uses TSDuck (https://tsduck.io/), while the HLS uses cURL.

## What will it output ?
The monitoring results will be saved into xml files, including the stream status (Online, Outage, or Warning). Information on the xml mainly consists of
### UDP monitoring
- Average bitrate
- Continuity count rate
- List of PIDs and their descriptions
### HLS monitoring
- Total bitrate
- Codecs
- Resolution
- HTTP return code
- Buffer time
- Chunk size
- Download properties (speed, time, and connect time)

A status compiler script is also available and can be ran optionally (eg.: using crontab, so it can produce periodic status of the monitored media stream). To complement this, a simple web interface is also provided which reads the compiled status, and able to display penalty-box like for problematic streams.

## Requirements
- Recent version of Linux, with these packages installed:
  - bash
  - sed
  - awk
  - dos2unix
  - bc
  - util-linux (for the command: "rev")
  - cURL (optional. For HLS monitoring)
  - crontab (optional. For scheduling status compiler script)
- TSDuck (optional. For MPEG UDP monitoring)
- HTTP server (optional. For serving the web interface)

## Configuration
- After the scripts has been downloaded, create/edit the configuration file. The configuration template is available from the `default.conf` file. It is highly advised that full paths are being used for the configurations related with files and directories.
- Populate the list with the streams that will be monitored. 
  - UDP based list supports multi-profile in separate multicast addresses. Refer to `udplist.csv` file for UDP list. 
  - HLS based list only supports single url in each lines, but this url may support multiple bitrate and all those bitrate profiles will be monitored. Refer to `hlslist.csv` for the HLS list formatting.
- Update the configuration file according to the list that will be used.
  
## Running
- To run the main script, use the `batchanalyze.sh` followed by the configuration file, such as :
  - `$ ./batchanalyze.sh default.conf`
- To run the status compiler script, use the `compiledata.sh` followed by the configuration file, such as :
  - `$ ./compiledata.sh default.conf`
