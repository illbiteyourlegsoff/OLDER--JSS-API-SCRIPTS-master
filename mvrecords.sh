#!/bin/bash
####################################################################################################
#
# Copyright (c) 2014, JAMF Software, LLC.  All rights reserved.
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
#Script for moving OS X Config Profiles and Policies from one JSS to another .
# Trey Howell, Professional Services Engineer, JAMF Software
#
#############################################################



##################WARNING TO USER
osascript -e 'Tell application "System Events" to display dialog "This will move OS X Policies,Smart Groups, Categories and Configuration Profiles, it will remove Scope" buttons {"Cancel", "Continue"} cancel button "Cancel" default button "Continue" with icon caution'

####VARIABLES


######## Asks for Variable for old JSS address
oldjss="$(osascript -e 'Tell application "System Events" to display dialog "Enter OLD JSS Address:" default answer "https://yourjssaddress.com:8443"' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$oldjss" ]; then
    # The user left the project name blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Address; cancelling..." as warning'
    exit 1 # exit with an error status
fi

######## asks for new JSS Address and adds variable
newjss="$(osascript -e 'Tell application "System Events" to display dialog "Enter NEW JSS Address:" default answer "https://yourjssaddress.com:8443"' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$newjss" ]; then
    # The user left the project name blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Address; cancelling..." as warning'
    exit 1 # exit with an error status
fi


############## asks for user for API and adds variable
apiuser="$(osascript -e 'Tell application "System Events" to display dialog "Enter API username: have same account on both JSS:" default answer ""' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$apiuser" ]; then
    # The user left the project name blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Address; cancelling..." as warning'
    exit 1 # exit with an error status
fi

######### asks for password for API users and adds variable
apipass="$(osascript -e 'Tell application "System Events" to display dialog "Enter API Password: have same account on both JSS:" default answer "" with hidden answer' -e 'text returned of result' 2>/dev/null)"
if [ $? -ne 0 ]; then
    # The user pressed Cancel
    exit 1 # exit with an error status
elif [ -z "$apipass" ]; then
    # The user left the project name blank
    osascript -e 'Tell application "System Events" to display alert "You must enter a JSS Address; cancelling..." as warning'
    exit 1 # exit with an error status
fi

#######manual variables
#oldjss=""
#apiuser=""
#apipass=""
#newjss=""



########### the 1 and then the second number is how many id's it will look through if you have more than 45 change 45 to one higher then you have
for i in {1..45}
do



##############################################
######
#######   DO NOT CHANGE BELOW THIS LINE!!!!!!
######
######
#################################################


#####moving Computers Records Over

####### Download Computers to XML file from old JSS  ###############################################################
curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/computers/id/$i > /tmp/computers.xml



####### upload xml file into new JSS for computer records
curl -k -s -u $apiuser:$apipass $newjss/JSSResource/computers/id/$i -T /tmp/computers.xml -X POST


#######Moving Categories from old JSS to new JSS ###############################################################

#########Download Categories from old JSS to xml file
curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/categories/id/$i > /tmp/cats.xml

############upload Categories from XML to new JSS
curl -k -s -u $apiuser:$apipass $newjss/JSSResource/categories/id/$i -T /tmp/cats.xml -X POST



########Computer Groups ###############################################################

###########Download Computer groups from old JSS to xml file
curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/computergroups/id/$i > /tmp/cpugrps.xml

#########upload Computer Groups from xml file to new JSS
curl -k -s -u $apiuser:$apipass $newjss/JSSResource/computergroups/id/$i -T /tmp/cpugrps.xml -X POST




#########Scripts ###############################################################
########
######### This doesn't work it won't pull the actual script--- Work in Progress
#########
#curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/scripts/id/$i > /tmp/scripts.xml

#curl -k -s -u $apiuser:$apipass $newjss/JSSResource/scripts/id/$i -T /tmp/scripts.xml -X POST

###############################

####### Policies convert over ###############################################################


##########Download the Policies from old JSS to xml file
curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/policies/id/$i > /tmp/policies.xml

########due to if certain items don't exist when we upload to new JSS it won't upload we remove them from the policy , we always remove scope so a policy just doesn't run as soon as it gets imported. Comment out and of the sed lines if your sure that line exists in new JSS

###### removes scope from policy
sed -ie 's/<scope>.*<\/scope>//g' /tmp/policies.xml

####removes any attached Packages from policy
sed -ie 's/<packages>.*<\/packages>//g' /tmp/policies.xml

###### removes any Categories from Policy
sed -ie 's/<category>.*<\/category>//g' /tmp/policies.xml

###### removes any scripts attached to policy
sed -ie 's/<scripts>.*<\/scripts>//g' /tmp/policies.xml

##### removes any Dock items
sed -ie 's/<dock>.*<\/dock>//g' /tmp/policies.xml

##### removes it from Self Service 
sed -ie 's/<self_service>.*<\/self_service>//g' /tmp/policies.xml


############## upload policies from xml to new JSS
curl -k -s -u $apiuser:$apipass $newjss/JSSResource/policies/id/$i -T /tmp/policies.xml -X POST


########## Moving over os X configuration Profiles ###############################################################


########## Download Configuration Profiles from old jss to xml file
curl -k -s -u $apiuser:$apipass $oldjss/JSSResource/osxconfigurationprofiles/id/$i > /tmp/configprofiles.xml

########due to if certain items don't exist when we upload to new JSS it won't upload we remove them from the configuration policy , we always remove scope so a policy just doesn't run as soon as it gets imported. Comment out and of the sed lines if your sure that line exists in new JSS

##### remove scope from Configuration profile
sed -ie 's/<scope>.*<\/scope>//g' /tmp/configprofiles.xml

##### remove Categories from Configuration Profiles
sed -ie 's/<category>.*<\/category>//g' /tmp/configprofiles.xml

####################upload Config PRofiles from xml to new JSS
curl -k -s -u $apiuser:$apipass $newjss/JSSResource/osxconfigurationprofiles/id/$i -T /tmp/configprofiles.xml -X POST


done


