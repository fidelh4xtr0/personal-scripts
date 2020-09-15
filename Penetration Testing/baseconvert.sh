#!/bin/bash

FILE=$1

while read p; do
	echo $p | base64
done < $FILE	
