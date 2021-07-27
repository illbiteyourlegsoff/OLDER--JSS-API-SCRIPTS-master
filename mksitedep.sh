#!/bin/sh


########################################
#
#
#This will take what site the computer is and make it also part of that department, 
#  The Sites and departments must already be created and match
#
#   Trey Howell 2015
#########################################



####JSS ADDRESS
apiURL="https://yourjss.com:8443"       ###<--- do not add slash at end, it is used in variable below


####API USERName must have read and write
apiUser="username"

#######API PASSWORD for above account
apiPass="password"

##################################################################################################
#
# Do not modify below this line
#
#
###############################################################################################

###
#####Serial number of computer

####sn="C17J7RJTTTY3"   <---- if wanting to hardcode a serial number
sn=`ioreg -l |grep IOPlatformSerialNumber | awk '{print $4}' | cut -d \" -f 2`


#####DEMO of what XML looks like
### <?xml version="1.0" encoding="UTF-8"?><computer><location><department>DECS</department></location></computer>
###
##3

######Queries for Site of Computer
siteName=$(curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn | xpath /computer/general/site/name[1] | sed 's,<name>,,;s,</name>,,')


###########Queries for old Department NOT NEEDED in this version of Script
#oldepName=$(curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn | xpath /computer/location/department | sed 's,<department>,,;s,</department>,,') 



######Creates XML file that will change Department
cat <<EOT > /tmp/sites.xml
<?xml version="1.0" encoding="UTF-8"?><computer><location><department>$siteName</department></location></computer>

EOT


###This uploads our XML file to write new Department based off of site
curl -k -s -u $apiUser:$apiPass $apiURL/JSSResource/computers/serialnumber/$sn -T /tmp/sites.xml -X PUT



####give time to upload
sleep 5

######remove xml file
rm /tmp/sites.xml
