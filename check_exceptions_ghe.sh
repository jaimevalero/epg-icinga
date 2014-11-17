#!/bin/sh
#######################################
#
# Check wether we have an exception on a github enterprise instance.
# Usefull to find wether we have run out of memory, or similar.
#
#
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0#
#
#  Author: Jaime Valero 78
#
#######################################

#######################################
# Variables
# Settings to be changed
LAST_MINUTES_TO_CHECK=5

# Variables
RETURN_CODE=''
CALCULATED_ERROR_MSG=''
WARN_MSG=''
ERROR_MSG=''

# Static parameters
RETURN_ERROR=2
STRING_ERROR='ERROR:'
RETURN_OK=0
STRING_OK='OK'

RETURN_WARN=1
STRING_WARN='Warning'

EXCEPTIONS_FILE=/var/log/github/exceptions.log
FILE_DATE=/tmp/file_date
FILE_TMP_DATE=/tmp/dates.check.tmp
# End of parameters
#######################################

CheckLogFilesAreRotating( )
{
# If file size are zero due to daily rotate, we return ok, to avoid false positives
[ ! -s $EXCEPTIONS_FILE ] && echo $STRING_OK. Empty exceptions file && exit $RETURN_OK 

}

PreWork( )
{

	CheckLogFilesAreRotating

	#Extract time file to parse
	rm -f $FILE_DATE $FILE_TMP_DATE 2>/dev/null
	for MINUTO in `seq 1 $LAST_MINUTES_TO_CHECK`
	do
				echo "date -d '$MINUTO minute ago' '+%Y-%m-%d %H:%M' >> $FILE_DATE" >>  $FILE_TMP_DATE
	done
	chmod +x  $FILE_TMP_DATE && . $FILE_TMP_DATE

				
}

PostWork( )
{
#	rm -f  $FILE_TMP_DATE $FILE_DATE  2>/dev/null
 a=0
}

LookForExceptions( )
{
     ERROR_MSG=`cat $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1  | grep -i -f $FILE_DATE | tail -1 | grep -o -e  "Errno::[a-zA-Z0-9]*\"\,\"message\":\"[a-zA-Z0-9 \-]*" | cut -d\" -f5 `

     WARN_MSG=`cat  $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1   | grep -i -f $FILE_DATE  `
}

CalculateReturnCode( )
{
	# Calculate Error MSG
	# 0 OK, 
	# 1 Error
	# If we have found an errror
	if [ `echo $ERROR_MSG | grep -i [a-z] | wc -l` -eq 1 ] 
	then
		RETURN_CODE=$RETURN_ERROR
                RETURN_STRING=$CALCULATED_ERROR_MSG
	else
                # We return warning if any content found on the last lines of the exceptions file, no matter its contents. 
                if [  `echo $WARN_MSG | grep -i [a-z] | wc -l` -ne 0 ]
		then
                        RETURN_CODE=$RETURN_WARN
                        RETURN_STRING=$CALCULATED_ERROR_MSG
                else
			RETURN_CODE=$RETURN_OK
			RETURN_STRING=$STRING_OK
                fi 
	fi

}

CalculateReturnString( )
{

MY_URL=`cat $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1  | grep -i -f $FILE_DATE | tail -1 | sed -e 's/^.*\"url\"//g'  | cut -d \" -f2`
MY_APP=`cat $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1  | grep -i -f $FILE_DATE | tail -1 | sed -e 's/^.*\"app\"//g'  | cut -d \" -f2`
MY_USER=`cat $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1  | grep -i -f $FILE_DATE | tail -1 | sed -e 's/^.*\"user\"//g'  | cut -d \" -f2`
MY_MESSAGE=`cat $EXCEPTIONS_FILE $EXCEPTIONS_FILE.1  | grep -i -f $FILE_DATE | tail -1 | sed -e 's/^.*\"message\"//g'  | cut -d \" -f2 |  cut -d'[' -f1`
CALCULATED_ERROR_MSG="App:$MY_APP user:$MY_USER url:$MY_URL message:$MY_MESSAGE"

}

# Main

# Previous Work
PreWork

# Check for exceptions
LookForExceptions

# Calculate return code acccording results
CalculateReturnString
CalculateReturnCode

# DeleteTempFiles
PostWork

echo $RETURN_STRING 
exit $RETURN_CODE

