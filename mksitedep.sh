#!/bin/sh


########################################
#
#
#This will take what site the computer is and make it also part of that department, 
#  The Sites and departments must already be created and match
#
#   Trey Howell 2015
#
#####
###Modified to work with Big Sur. xpath requires new attributes July 2021 -- Trey Howell
#########################################



####JSS ADDRESS
apiURL="https://yourjss.com:8443"       ###<--- do not add slash at end, it is used in variable below


####API USERName must have read and write
apiUser="username"

#######API PASSWORD for above account
apiPass="password"

###Having issues with base64 encoded creds. Will work on this. 
encodedCredentials=$( printf "$apiUser:$apiPass" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )


##################################################################################################
#
# Do not modify below this line
#
#
###############################################################################################

###
#####Serial number of computer

#sn="FVFYN33FHV2H"  ###<---- if wanting to hardcode a serial number
sn=`ioreg -l |grep IOPlatformSerialNumber | awk '{print $4}' | cut -d \" -f 2`


#####DEMO of what XML looks like
### <?xml version="1.0" encoding="UTF-8"?><computer><location><department>DECS</department></location></computer>
###
##3

######Queries for Site of Computer
#echo "curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn | xpath /computer/general/site/name[1] | sed 's,<name>,,;s,</name>,,'"
siteName=$(curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn | xpath -e /computer/general/site/name | sed 's,<name>,,;s,</name>,,')
echo $siteName 

###########Queries for old Department NOT NEEDED in this version of Script
#oldepName=$(curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn | xpath /computer/location/department | sed 's,<department>,,;s,</department>,,') 



######Creates XML file that will change Department
#cat <<EOT > /tmp/sites.xml
#<?xml version="1.0" encoding="UTF-8"?><computer><location><department>$siteName</department></location></computer>

#EOT

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><computer><location><department>$siteName</department></location></computer>" > /tmp/sites.xml
###This uploads our XML file to write new Department based off of site
curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn -T /tmp/sites.xml -X PUT



####give time to upload
sleep 5

######remove xml file
rm -f /tmp/sites.xml
