#!/usr/bin/env bash

#---BEGIN GLOBAL VARIABLES---#

#--recuperation du nom du script et du nom du serveur
readonly SCRIPT_NAME=$(basename "$0") 
SERVER=$(hostname -s)

# creation du fichier et repertoire des logs
LOGDIR=/var/custom-script-logs
LOGFILE=$LOGDIR/$SCRIPT_NAME-$SERVER.log
if [ ! -e "$LOGDIR" ] ; then
        mkdir "$LOGDIR"
fi
/bin/touch "$LOGFILE"

#---END GLOBAL VARIABLES---



#---BEGIN FUNCTIONS---


# Uses the logger command to log messages to syslog and tees the same message to a file
function log()
{
  echo "$@"
  echo "$@" | tee -a "$LOGFILE" | logger -i "$SCRIPT_NAME" -p user.notice
}

# Uses the logger command to log error messages to syslog and tees the same message to a file
function err()
{
  echo "$@" >&2
  echo "$@" | tee -a "$LOGFILE" | logger -i "$SCRIPT_NAME" -p user.error
}

# fonction get_active_ambari_host()
function get_active_ambari_host()
{
        USERID=$1
        PASSWD=$2
        HOST1="hn0-$(hostname |cut -d"-" -f2- )"
        HOST2="hn1-$(hostname |cut -d"-" -f2- )"

                HTTP_RESPONSE=$(curl -i --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent "http://${HOST1}:8080")
                # extract the status
                HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

        if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -le 299 ]]; then
                echo $HOST1
        else
                echo $HOST2
        fi
}

#---END FUNCTIONS---






#---BEGIN MAIN PROGRAM---

# recuperation du fichier de configuration d'AMBARI
USER_CLIENT_ID=$1
USER_KEY=$2
USER_DIRECTORY_ID=$3
KEY_VAULT_NAME=$4

AMBARICONFIGS_SH=/var/lib/ambari-server/resources/scripts/configs.sh

# recuperation du watchdog username et password, pour la creation des comptes utilisateurs dans AMBARI
USERID=$(sudo python -c "import hdinsight_common.Constants as Constants;print Constants.AMBARI_WATCHDOG_USERNAME")
PASSWD=$(sudo python -c "import hdinsight_common.ClusterManifestParser as ClusterManifestParser;import hdinsight_common.Constants as Constants;import base64;base64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password;print base64.b64decode(base64pwd)")


# Get the cluster name
CLUSTERNAME=$(python -c "import hdinsight_common.ClusterManifestParser as ClusterManifestParser; print ClusterManifestParser.parse_local_manifest().deployment.cluster_name;")

# Get the active Ambari host (we need to do this because the node that Ambari runs on can change if it fails over to a different head node)
ACTIVEAMBARIHOST=$(get_active_ambari_host $USERID $PASSWD)

# Delete the file if it already exists
[ -e "/tmp/user-list.csv" ] && rm "/tmp/user-list.csv"


hdfs dfs -test -e "adl:///add-users/user-list.csv"
if [ $? != 0 ]; then
        log "Error the user list file does not exist on HDFS at the expected location adl:///add-users/user-list.csv"
        exit 1
fi

# copier le fichier user-list.csv du data lake vers /tmp/
hdfs dfs -copyToLocal "adl:///add-users/user-list.csv" /tmp/



OLDIFS=$IFS
while IFS='|' read firstname lastname username uid gid osusertype ambarigroup
do
        if [ ! "$firstname" == "firstname" ]; then
                echo "CSV LINE:$firstname|$lastname|$username|$uid|$gid|$osusertype|$ambarigroup"

                if [ -z "$firstname" ] && [ -z "$lastname" ] && [ -z "$username"] && [ -z "$uid" ] && [ -z "$gid" ] && [ -z "$osusertype" ] && [ -z "$ambarigroup" ]; then
                        log "The user list CSV file does not contain the expected columns or a field is empty."
                else


                                log "Creating a new OS user: $username with uid $uid and gid $gid"
                                useradd -m -u "$uid" -U -s /bin/bash "$username"
								
	########################################################################################################################							
								
								
							   token=$(curl -X POST -d 'grant_type=client_credentials&client_id=$USER_CLIENT_ID&client_secret=$USER_KEY&resource=https://vault.azure.net' https://login.microsoftonline.com/d3f969e5-42a3-4d6c-a617-7b969dd92ea1/oauth2/token | cut -d ',' -f 7 | cut -d ':' -f 2 | cut -d '"' -f 2)

                               userpassword=$(curl -H "Authorization: Bearer $token" -vv https://$KEY_VAULT_NAME.vault.azure.net/secrets/aaa-hdi-$username?api-version=7.0 | cut -d ',' -f 1 | cut -d ':' -f 2 | cut -d '"' -f 2)

                               echo -e "$userpassword" | passwd "$username"
                               log "Added user $username"



                        # only run these commands once on one of the head nodes

                        if [[ "$(hostname -s)" == hn0* ]]; then
                          

                                        log "Creating ambari user ${username}"

                                        HTTP_RESPONSE=$(curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "{\"Users/user_name\":\"${username}\",\"Users/password\":\"${userpassword}\",\"Users/active\":\"true\",\"Users/admin\":\"false\"}" "http://${ACTIVEAMBARIHOST}:8080/api/v1/users")

                                        response_code=$(curl -u "$USERID:$PASSWD" -w %{http_code} -o /dev/null -i -H 'X-Requested-By:ambari' -X PUT -d '{"Users" : {"admin" : "true"}}' http://headnodehost:8080/api/v1/users/$username)


                                        log "Creating ambari group ${ambarigroup}"

                                        HTTP_RESPONSE=$(curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "{\"Groups/group_name\":\"${ambarigroup}\"}" "http://${ACTIVEAMBARIHOST}:8080/api/v1/groups")


                                        log "Adding ${username} to the group ${ambarigroup} in Ambari"

                                        HTTP_RESPONSE=$(curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "[{\"MemberInfo/user_name\":\"${username}\", \"MemberInfo/group_name\":\"${ambarigroup}\"}]" "http://${ACTIVEAMBARIHOST}:8080/api/v1/groups/${ambarigroup}/members")


                        fi

                fi
        fi
done < "/tmp/user-list.csv"
IFS=$OLDIFS




#end if [[ "$(hostname -s)" == hn0* ]]; then

# Delete the local file and the one on Azure storage
[ -e "/tmp/$user-list.csv" ] && rm "/tmp/user-list.csv"


exit 0

#---END MAIN PROGRAM---
