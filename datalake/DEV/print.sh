#!/bin/bash
#Headnode only run from one machine s
HEADNODE=hn0
while (( $#> 0));do
		if [ $1 = "admin" ]
		then
			#set admin credentials for ambari
			ambariadminuser="admin"
			ambariadminpass=$2
		else
			#create Ambari user
			#only run on headnode
			if hostname | grep $HEADNODE 2>&1 > /dev/null
			then
				echo "Adding user $1 to Ambari dashboard"
				curl -iv -u admin:$ambariadminpass -H "X-Requested-By: ambari" -X POST -d  '{"Users/user_name":"'$1'","Users/password":"'$2'","Users/active":"true","Users/admin":"true"}' http://hn0-test:8080/api/v1/users
			else
				echo "This is not the headnode"
			fi
							
		fi
    shift 3
done
