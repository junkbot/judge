#!/bin/bash

# file:			stripFile.sh
# description: 	takes in a file and removes leading and
#			   	trailing whitespace from each line in it
# usage
# author:		joshua lau
# date:			12 july 2010
# version:		1.0

# a function to tell a user how to use this script
usage() {
	# echo out line-by line, the usage and description
	echo USAGE: bash stripFile.sh [FILE]
	echo Strips the trailing and leading whitespace echo from each line in FILE.
}

# a function that takes in a string as a first argument
# and return the string stripped of its leading and
# trailing whitespace
stripSpace() {
	# THIS FUNCTION NOT OPERATIONAL!
	# give the string a good name
	stringToStrip=$1

	# remove trailing whitespace
	stringToStrip="${stringToStrip## }"

	# remove leading whitespace
	stringToStrip="${stringToStrip%% }"

	# return the new string
	echo "$stringToStrip"
}

x=$(stripSpace "  hello  ")
echo x=\"$x\"

# check if there are sufficient arguments
if [ "$#" -eq "0" ]
then
	# tell them how to use the script
	# and abort
	usage
	exit 1
fi

# check if they are asking for help
if [ "$1" == "--help" ]
then
	# tell them how to use the script
	# and exit successfully
	usage
	exit 0
fi

# give the filename an appropriate name
fileName=$1

# check if given file exists
if [ ! -e $fileName ]
then
	# tell them it doesn't exist and abort
	echo ERROR: file does not exist
	exit 1
fi

# find the number of lines in the file
numLines=$(wc -l $fileName)
numLines="${numLines% *}"

# open the file for reading
exec 3<> "$fileName"

# for each line strip it
for ((i="0";i<$numLines;i+=1))
do
	echo i=$i
	# read in the next line
	read lineToChange

	# run it against the function and
	# assign changedLine to the return value
	changedLine=$(stripSpace $lineToChange)

	echo changedLine=$changedLine

	# append the stripped line to the given file
	echo "$changedLine" >> $fileName
done

# remove the original lines for the file
for ((i="0";i<$numLines;i+=1))
do
	# remove the top line
	sed -i '1 d' $fileName
done

# close the file
exec 3>&-
