#!/bin/bash
####################################################################################################
#
# Copyright (c) 2015, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
##############
#
# Trey Howell, Professional Services Engineer, JAMF Software
#Self Service item, to verify user exists in ldap, then add the user info to computer record
#############################################################




####JSS ADDRESS
apiURL="https://myjssaddress"       ###<--- do not add slash at end, it is used in variable below








##################################################################################################
#
# Do not modify below this line
#
#
###############################################################################################

###
#####Serial number of computer

sn=`ioreg -l |grep IOPlatformSerialNumber | awk '{print $4}' | cut -d \" -f 2`




############## asks user for Network account
acctuser="$(osascript -e 'Tell application "System Events" to display dialog "Please enter your network user ID:" default answer "username@domain.com"' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$acctuser" ]; then
    
    osascript -e 'Tell application "System Events" to display alert "You must enter a username; cancelling..." as warning'
    exit 1 # exit with an error status
fi

######### asks for password for API users and adds variable
acctpass="$(osascript -e 'Tell application "System Events" to display dialog "Please enter your Network Password:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$acctpass" ]; then
    # The user left the project name blank
    osascript -e 'Tell application "System Events" to display alert "You must enter your password; cancelling..." as warning'
    exit 1 # exit with an error status
fi




######Does a LDAP Query using the JSS and API, to verify user has rights
ldap=$(curl -k -s -u $acctuser:$acctpass $apiURL/JSSResource/ldapservers/id/1/user/$acctuser | grep "Status" | sed 's,<title>,,;s,</title>,,')


##############Verifies user has a valid LDAP account and if does not it gives a error. If does does a recon with that account to add it jss.

if [[ "$ldap" != "" ]]; then
	osascript -e 'Tell application "System Events" to display alert "Try Login  Again, could not verify username or password" as warning'
	exit 1
else
  sudo jamf recon -endUsername "$acctuser"

fi

 
