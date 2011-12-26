#!/bin/bash

# this is a simple tester that takes in a program name
# as its first command line argument, x, in either
# C, C++ or Pascal, compiles it using the appropriate
# compiler, and runs it against test files x.k.in where
# k is the test number, and gives the output in x.k.out
# (assumes x does i/o with x.in and x.out)
# the second command line argument is the username
# which has to exist

#######################################################
# FUNCTION DEFINITIONS

# a function to tell a user how to use this script
usage() {
	# echo out line-by-line, the usage and description
	echo USAGE: bash tester.sh [FILE] [USER]
	echo takes in a C, C++ or Pascal file and judges it against test data
}

# compares 2 files by stripping extra whitespace
# in each of the files and using diff
# WARNING: don't use with string problems
# RETURNS: true if same or false otherwise
comp() {
	python lib/stripSpace.py $(pwd)/$1
	python lib/stripSpace.py $(pwd)/$2

	dout=$(diff -B -b --brief $1 $2)

	if [ -z "$dout" ]
	then
		return "1"
	else
		return "0"
	fi
}
#######################################################

# Test if there are enough arguments
if [ "$#" -lt "2" ]
then
	# tell them how to use the script and abort
	usage
	exit 1
fi

# Test if the file exists #############################

# the first argument should be the filename
# give an error if it doesn't exist
if [ ! -e $1 ]
then
	echo "ERROR: $1 does not exist"
	exit 1
fi

progName="${1%.*}"
fileExtension="${1##*.}"

userName=$2

# check just in case if the user doesn't exist
# and throw an error and abort if this is so
if [ ! -e submissions/$userName ]
then
	echo ERROR: user does not exist.
	exit 1
fi

# Test if there exists a problem with the given name
if [ ! -e problems/$progName ]
then
	# if such a problem does not exist,
	# throw an error and abort
	echo ERROR: no such problem: $progName. Make sure the [FILE] matches [PROBLEM_NAME].[FILE_EXTN].
	exit 1
fi

# check if they have any submissions for this
# problem so far, if not, make a new directory
if [ ! -e submissions/$userName/$progName ]
then
	# make the directory
	mkdir submissions/$userName/$progName
	touch submissions/$userName/$progName/$progName.scores
	lastNumber=0
else
	# it exists, find the number of the last
	# submission and get the next number
	lastSubmission=$(ls -v submissions/$userName/$progName/ | tail -n 1)

	# work out the number of the last submission
	# in 2 steps; <problemName>.attemptNumber.<extension>
	lastNumber="${lastSubmission%.*}"
	lastNumber="${lastNumber#*.}"
fi

# work out the attempt number of this submission
newAttempt=$(($lastNumber+1))

echo "Attempt #$newAttempt"
echo

# Test if we accept the filetype, Compile #############

# catch the program name (everything before the last '.')
# which we will use to name the compiled executable and the
# extension which will tell us what compiler to use and if
# we accept the given file type

compilerOutput=""

if [ "$fileExtension" = "c" ] 
then
	echo "Compiling..."
	compilerOutput=$(gcc $1 -o $progName -m32 -O2 -lm 2>&1)
elif [ "$fileExtension" = "cpp" ] 
then
	echo "Compiling..."
	compilerOutput=$(g++ $1 -o $progName -m32 -O2 -lm 2>&1)
elif [ "$fileExtension" = "pas" ] 
then
	echo "Compiling..."
	compilerOutput=$(fpc $1 -O2 -Sd -Sh 2>&1)
else
	echo ERROR: files must be either .c, .cpp or .pas
	exit 1
fi

# echo compiler output is:
# echo
# echo $compilerOutput
# echo
# echo end compiler output

# test whether or not it compiled
if [ ! -e $progName ]
then
	echo 
	echo ERROR: does not compile:
	echo 
	echo $compilerOutput
	exit 1
fi

# Run it against testcases ############################

# Read in testcase data ###############################
exec 3<> "problems/$progName/$progName.data"
read timeLimit <&3
read heapLimit <&3
read stackLimit <&3

echo ""
echo Running on $(hostname)...
echo ""
echo JUDGE
echo "CASES: Num | Score |       Reason      |   Time  "
echo "       ----+-------+-------------------+----------"

total="0"
totalTime="0"
shopt -s nullglob
for i in problems/$progName/$progName.[0-9].in problems/$progName/$progName.[0-9][0-9].in; do
	correctOutputFile="${i%%.in}.out"

	testNumber="${i%%.in}"
	testNumber="${testNumber##*.}"

	outputFile="$progName.out"
	read caseWeight <&3

	if [ -e $outputFile ]
	then
		rm -f $outputFile
	fi
	cp $i $progName.in

# Check for correctness, runs in time ##################
	if [ $testNumber -lt "10" ]
	then
		echo -n "        #$testNumber |  "
	else
		echo -n "       #$testNumber |  "
	fi

#	the fail memlimit
#	ulimit -s $stackLimit

# Run it and catch its elapsed time
	timeElapsed=$( /usr/bin/time -f "%e" 2>&1 timelimit -t $timeLimit -T $timeLimit ./$progName )
	newTimeElapsed="${timeElapsed:0:9}"

	if [ "$newTimeElapsed" == "timelimit" ]
	then
		echo "  0  | timeout           |"
	else
		# check if it used too much memory
		memOutput=$( bash -c "ulimit -v $heapLimit -s $stackLimit && ./$progName" )
		diedCheck=${memOutput/Killed/thisfailed/}
		segCheck=${memOutput/Segmentation fault/thisepicfailed/}

		if [ "$diedCheck" != "$memOutput" ]
		then
			echo -n "  0  | out of memory     |    $timeElapsed"
		elif [ "$segCheck" != "$memOutput" ]
		then
			echo -n "  0  | crashed           |    $timeElapsed"
		else
			if [ ! -e "$outputFile" ]
			then
				echo -n "  0  | empty output file |    $timeElapsed"
			else
				comp "$outputFile" "$correctOutputFile"
				score=$?
				if [ $score = "1" ]
				then
					echo -n "100  | correct           |    $timeElapsed"
					total=$(($total+$caseWeight))
				else
					echo -n "  0  | incorrect         |    $timeElapsed"
				fi
			fi
		fi
		totalTime=$(/usr/bin/gcalctool -s $totalTime+$timeElapsed)

		echo "s"
	fi
done

# close the data file
exec 3>&-

# add up total score, time
echo "TOTAL: $total"
echo
echo -n "Total time: $totalTime"
echo "s"

# delete all the unwanted files
rm -f $progName
rm -f $progName.o
rm -f $progName.in
rm -f $progName.out

# move the submission to a new file
mv $1 submissions/$userName/$progName/$progName.$newAttempt.$fileExtension

# update the .scores file

curDate=$(date)

if [ "$newAttempt" -eq "1" ]
then
	# append to back
	echo -e "Attempt\t#$newAttempt\t.$fileExtension\t$total%\t${totalTime}s\t$(date)" >> submissions/$userName/$progName/$progName.scores
else
	# append to front
	sed -i 1i\ Attempt\\t#$newAttempt\\t.$fileExtension\\t$total%\\t${totalTime}s\\t"${curDate}" submissions/$userName/$progName/$progName.scores
fi

exit 0
