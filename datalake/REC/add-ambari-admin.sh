#! /bin/bash

if [ -z "$1" ]
then
                echo "user list must be provided"
                exit 1
fi

USERID=$(echo -e "import hdinsight_common.Constants as Constants\nprint Constants.AMBARI_WATCHDOG_USERNAME" | python)

PASSWD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nimport hdinsight_common.Constants as Constants\nimport base64\nbase64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password\nprint base64.b64decode(base64pwd)" | python)

IFS=':' read -a arr <<< "$1"

for x in "${arr[@]}"
do
	i=0
	response_code=$(curl -u $USERID:$PASSWD -w  %{http_code} -o /dev/null -i -X GET http://headnodehost:8080/api/v1/users/$x)
	while [ "$response_code" != 200 ] && [ $i -lt 5 ]
	do
		echo "user $x does not exist"
		sleep 12
		let "i++"
		response_code=$(curl -u $USERID:$PASSWD -w  %{http_code} -o /dev/null -i -X GET http://headnodehost:8080/api/v1/users/$x)
	done
	
	if [ $i == 5 ]
	then
		echo "user $x is not added as admin"
	fi
			
        #echo "$x"
        response_code=$(curl -u "$USERID:$PASSWD" -w %{http_code} -o /dev/null -i -H 'X-Requested-By:ambari' -X PUT -d '{"Users" : {"admin" : "true"}}' http://headnodehost:8080/api/v1/users/$x)
        if [ "$response_code" == 200 ]
        then
        	echo "add $x as admin"
        fi
done
