# Creating a user in Ambari

curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "{\"Users/user_name\":\"${username}\",\"Users/password\":\"${userpassword}\",\"Users/active\":\"true\",\"Users/admin\":\"false\"}" "http://${ACTIVEAMBARIHOST}:8080/api/v1/users")



# Create a group in Ambari

curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "{\"Groups/group_name\":\"${ambarigroup}\"}" "http://${ACTIVEAMBARIHOST}:8080/api/v1/groups



# Add a user to a group in Ambari

curl -iv --write-out "HTTPSTATUS:%{http_code}" --output /dev/null --silent -u "$USERID:$PASSWD" -H "X-Requested-By: ambari" -X POST -d "[{\"MemberInfo/user_name\":\"${username}\", \"MemberInfo/group_name\":\"${ambarigroup}\"}]" "http://${ACTIVEAMBARIHOST}:8080/api/v1/groups/${ambarigroup}/members