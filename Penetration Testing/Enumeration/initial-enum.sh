#!/bin/bash

#############################################
#This is a script to run initial enumeration#
#of a target machine.                       #
#############################################

nmap_enum() {
  nmap $speed -sV -p- $ip > ~/Documents/Notes/$hostname/$hostname.nmap
  
  fail_string="Note: Host seems down."
  
  if [[ "$(cat ~/Documents/Notes/$hostname/$hostname.nmap)" == *"$fail_string"* ]]; then 
  	nmap -T4 -Pn -p- $ip > ~/Documents/Notes/$hostname/$hostname.nmap
  fi
        
}

analyze_nmap() {
   if [[ "$(cat ~/Documents/Notes/$hostname/$hostname.nmap)" == *"80/tcp"* ]]; then
   	echo "Web server found. Analyzing..."
   	web_server=true
   else
   	echo "No web server found."
   fi
   
   if [[ "$(cat ~/Documents/Notes/$hostname/$hostname.nmap)" == *"53/tcp"* ]]; then
   	dns=true
   fi
}

nikto_enum() {
  echo "Scanning vulnerabilities..."
  nikto -h $ip > ~/Documents/Notes/$hostname/$hostname.nikto
}

dns_enum() {
  echo "DNS Found. Running DNS Enumeration..."
  nslookup $ip $ip > ~/Documents/Notes/$hostname/$hostname.nslookup
  result=$(cat ~/Documents/Notes/$hostname/$hostname.nslookup | awk '{print $4}')
  if [[ $result == *"ns1"* ]]; then
  	result="${result//ns1.}"
  fi  
  dig axfr $result @$ip > ~/Documents/Notes/$hostname/$hostname.dig
}



while getopts 'i:h:s:' opt; do
  case "$opt" in
    i)
      ip=$OPTARG
      ;;
    h)
      hostname=$OPTARG
      ;;
    s)
      speed=$OPTARG
      ;;
    ? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    esac
done
shift "$((OPTIND -1))"  

    

speed="-T$speed"

echo $speed

directory="~/Documents/Notes/$hostname"
mkdir ~/Documents/Notes/$hostname

nmap_enum
analyze_nmap

if [[ "$web_server" == true ]]; then {
  nikto_enum
  }
fi

if [[ "$dns" == true ]]; then {
  dns_enum
}
fi

echo "Scan complete"

