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

# Static parameters
RETURN_ERROR=2
STRING_ERROR='ERROR:'
RETURN_OK=0
STRING_OK='OK'

FILE_DATE=/tmp/file_date
FILE_TMP_DATE=/tmp/dates.check.tmp
# End of parameters
#######################################

PreWork( )
{
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
	rm -f  $FILE_TMP_DATE $FILE_DATE  2>/dev/null

}

LookForExceptions( )
{
     ERROR_MSG=`cat /var/log/github/exceptions.log /var/log/github/exceptions.log.1 | grep -i -f $FILE_DATE | tail -1 | grep -o -e  "Errno::[a-zA-Z0-9]*\"\,\"message\":\"[a-zA-Z0-9 \-]*" | cut -d\" -f5 `


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
		RETURN_STRING=$STRING_ERROR
	else
		RETURN_CODE=$RETURN_OK
		RETURN_STRING=$STRING_OK
	fi

}

# Main

# Previous Work
PreWork

# Check for exceptions
LookForExceptions

# Calculate return code acccording results
CalculateReturnCode

# DeleteTempFiles
PostWork

echo $RETURN_STRING $ERROR_MSG
exit $RETURN_CODE


