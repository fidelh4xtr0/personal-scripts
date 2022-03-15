#!/bin/bash

#############################################
#This is a script to run initial enumeration#
#of a target machine.                       #
#############################################

nmap_enum() {                                                                                                                                                
  nmap $speed -sV -p- -sC -A $ip -v -oA ~/Documents/Notes/$hostname/$hostname                                                                                
                                                                                                                                                             
  fail_string="Note: Host seems down."                                                                                                                       
                                                                                                                                                             
  if [[ "$(cat ~/Documents/Notes/$hostname/$hostname.nmap)" == *"$fail_string"* ]]; then                                                                     
        nmap $speed -Pn -p- -sC -sV -A $ip -v -oA ~/Documents/Notes/$hostname/$hostname                                                                      
  fi                                                                                                                                                         
                                                                                                                                                             
}    


analyze_nmap() {
  portlist=()
  while read line; do
    if [[ "$(echo $line)" == *tcp* ]]; then
      if [[ "$(echo $line)" == *http* ]]; then
        portlist+=("${line:0:7}  ${line:14:9}")
        fi
      fi
    done < ~/Documents/Notes/$hostname/$hostname.nmap
  
  for port in "${portlist[@]}"
  do
    p="$(echo $port | sed 's/[^0-9]*//g')"
    if [[ "$(echo $port)" == *"http"* ]]; then
      echo "Web Server found on port $p"
      web_server=true
      fi
    if [[ "$(echo $port)" == *"https"* ]]; then
      echo "Secure Web Server Found on port $p"
      secure_web_server=true
      fi
  done

}

dirbust(){
  wordlist="/usr/share/wordlists/dirb/big.txt"
  for port in "${portlist[@]}"
  do 
    p="$(echo $port | sed 's/[^0-9]*//g')"
    echo "Busting directories in port $p"
    echo "###################$p###################" >> ~/Documents/Notes/$hostname/$hostname.dbust
	    if [[ $p  = *"https"* ]]; then
      gobuster dir -u https://$ip:$p -w $wordlist -x php,txt,log,sh,aspx,html -k -r >> ~/Documents/Notes/$hostname/$hostname.dbust
    else 
      gobuster dir -u http://$ip:$p -w $wordlist -x php,txt,log,sh,aspx,html -k -r >> ~/Documents/Notes/$hostname/$hostname.dbust
    fi
  done
}

nikto_enum() {
  echo "Scanning vulnerabilities..."
  nikto -h $ip > ~/Documents/Notes/$hostname/$hostname.nikto
  if [[ "$secure_web_server" == true ]]; then
    echo "" >> ~/Documents/Notes/$hostname/$hostname.nikto
    echo "" >> ~/Documents/Notes/$hostname/$hostname.nikto
    echo "" >> ~/Documents/Notes/$hostname/$hostname.nikto
    nikto -h $ip:8080 >> ~/Documents/Notes/$hostname/$hostname.nikto
  fi
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


mkdir ~/Documents/Notes/$hostname

nmap_enum
analyze_nmap

if [[ "$web_server" == true || "$secure_web_server" == true ]]; then {
  dirbust || true
  }
fi

if [[ "$web_server" == true || "$secure_web_server" == true ]]; then {
  nikto_enum || true
  }
fi



#if [[ "$dns" == true ]]; then {
#  dns_enum
#}
#fi

echo "Scan complete"

