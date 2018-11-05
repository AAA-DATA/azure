#! /bin/bash

# Declare variables
USERID=$(echo -e "import hdinsight_common.Constants as Constants\nprint Constants.AMBARI_WATCHDOG_USERNAME" | python)
PASSWD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nimport hdinsight_common.Constants as Constants\nimport base64\nbase64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password\nprint base64.b64decode(base64pwd)" | python)
TAG='notebookconf'
STORAGEACCOUNT='staaadatahdinsight'
STORAGEKEY='nzMQVaSKaKkBOGueDpdDwWS9s/UN7GHTROB4qXySnop8xc8+5X5ulzGuNXK+9z+x/SwpA+OV4ROUkxcxSPBulA=='
ENVIRONMENT='dev'

## Update conf
#curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-config","tag":"default","properties":{"zeppelin.anonymous.allowed" : "true","zeppelin.config.fs.dir" : "file:///etc/zeppelin/conf/","zeppelin.interpreter.config.upgrade" : "true","zeppelin.interpreter.connect.timeout" : "30000", "zeppelin.interpreter.dir" : "interpreter","zeppelin.interpreter.group.order" : "livy,md,sh,angular,jdbc","zeppelin.interpreters" : "org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter","zeppelin.notebook.azure.connectionString" : "DefaultEndpointsProtocol=https;AccountName=staaadatahdinsight;AccountKey=nzMQVaSKaKkBOGueDpdDwWS9s/UN7GHTROB4qXySnop8xc8+5X5ulzGuNXK+9z+x/SwpA+OV4ROUkxcxSPBulA==","zeppelin.notebook.azure.share" : "zeppelin", "zeppelin.notebook.dir" : "notebook", "zeppelin.notebook.homescreen" : " ", "zeppelin.notebook.homescreen.hide" : "false", "zeppelin.notebook.public" : "false","zeppelin.notebook.s3.bucket" : "zeppelin","zeppelin.notebook.s3.user" : "user", "zeppelin.notebook.storage" : "org.apache.zeppelin.notebook.repo.AzureNotebookRepo", "zeppelin.server.addr" : "0.0.0.0","zeppelin.server.allowed.origins" : "*", "zeppelin.server.authorization.header.clear" : "false","zeppelin.server.port" : "9995","zeppelin.server.ssl.port" : "9995","zeppelin.ssl" : "false","zeppelin.ssl.client.auth" : "false","zeppelin.ssl.key.manager.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.key.manager.password","zeppelin.ssl.keystore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.keystore.password","zeppelin.ssl.keystore.path" : "conf/keystore","zeppelin.ssl.keystore.type" : "JKS","zeppelin.ssl.truststore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.truststore.password","zeppelin.ssl.truststore.path" : "conf/truststore", "zeppelin.ssl.truststore.type" : "JKS", "zeppelin.websocket.max.text.message.size" : "1024000"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/aaa-hdi-dev/curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-config","tag":"default","properties":{"zeppelin.anonymous.allowed" : "true","zeppelin.config.fs.dir" : "file:///etc/zeppelin/conf/","zeppelin.interpreter.config.upgrade" : "true","zeppelin.interpreter.connect.timeout" : "30000", "zeppelin.interpreter.dir" : "interpreter","zeppelin.interpreter.group.order" : "livy,md,sh,angular,jdbc","zeppelin.interpreters" : "org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter","zeppelin.notebook.azure.connectionString" : "DefaultEndpointsProtocol=https;AccountName=staaadatahdinsight;AccountKey=nzMQVaSKaKkBOGueDpdDwWS9s/UN7GHTROB4qXySnop8xc8+5X5ulzGuNXK+9z+x/SwpA+OV4ROUkxcxSPBulA==","zeppelin.notebook.azure.share" : "zeppelin-$environment", "zeppelin.notebook.dir" : "notebook", "zeppelin.notebook.homescreen" : " ", "zeppelin.notebook.homescreen.hide" : "false", "zeppelin.notebook.public" : "false","zeppelin.notebook.s3.bucket" : "zeppelin","zeppelin.notebook.s3.user" : "user", "zeppelin.notebook.storage" : "org.apache.zeppelin.notebook.repo.AzureNotebookRepo", "zeppelin.server.addr" : "0.0.0.0","zeppelin.server.allowed.origins" : "*", "zeppelin.server.authorization.header.clear" : "false","zeppelin.server.port" : "9995","zeppelin.server.ssl.port" : "9995","zeppelin.ssl" : "false","zeppelin.ssl.client.auth" : "false","zeppelin.ssl.key.manager.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.key.manager.password","zeppelin.ssl.keystore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.keystore.password","zeppelin.ssl.keystore.path" : "conf/keystore","zeppelin.ssl.keystore.type" : "JKS","zeppelin.ssl.truststore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.truststore.password","zeppelin.ssl.truststore.path" : "conf/truststore", "zeppelin.ssl.truststore.type" : "JKS", "zeppelin.websocket.max.text.message.size" : "1024000"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/$1/
curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-config","tag":"default","properties":{"zeppelin.anonymous.allowed" : "true","zeppelin.config.fs.dir" : "file:///etc/zeppelin/conf/","zeppelin.interpreter.config.upgrade" : "true","zeppelin.interpreter.connect.timeout" : "30000", "zeppelin.interpreter.dir" : "interpreter","zeppelin.interpreter.group.order" : "livy,md,sh,angular,jdbc","zeppelin.interpreters" : "org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter","zeppelin.notebook.azure.connectionString" : "DefaultEndpointsProtocol=https;AccountName=$STORAGEACCOUNT;AccountKey=$STORAGEKEY","zeppelin.notebook.azure.share" : "zeppelin-$ENVIRONMENT", "zeppelin.notebook.dir" : "notebook", "zeppelin.notebook.homescreen" : " ", "zeppelin.notebook.homescreen.hide" : "false", "zeppelin.notebook.public" : "false","zeppelin.notebook.s3.bucket" : "zeppelin","zeppelin.notebook.s3.user" : "user", "zeppelin.notebook.storage" : "org.apache.zeppelin.notebook.repo.AzureNotebookRepo", "zeppelin.server.addr" : "0.0.0.0","zeppelin.server.allowed.origins" : "*", "zeppelin.server.authorization.header.clear" : "false","zeppelin.server.port" : "9995","zeppelin.server.ssl.port" : "9995","zeppelin.ssl" : "false","zeppelin.ssl.client.auth" : "false","zeppelin.ssl.key.manager.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.key.manager.password","zeppelin.ssl.keystore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.keystore.password","zeppelin.ssl.keystore.path" : "conf/keystore","zeppelin.ssl.keystore.type" : "JKS","zeppelin.ssl.truststore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.truststore.password","zeppelin.ssl.truststore.path" : "conf/truststore", "zeppelin.ssl.truststore.type" : "JKS", "zeppelin.websocket.max.text.message.size" : "1024000"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/aaa-hdi-dev/curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-config","tag":"default","properties":{"zeppelin.anonymous.allowed" : "true","zeppelin.config.fs.dir" : "file:///etc/zeppelin/conf/","zeppelin.interpreter.config.upgrade" : "true","zeppelin.interpreter.connect.timeout" : "30000", "zeppelin.interpreter.dir" : "interpreter","zeppelin.interpreter.group.order" : "livy,md,sh,angular,jdbc","zeppelin.interpreters" : "org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter","zeppelin.notebook.azure.connectionString" : "DefaultEndpointsProtocol=https;AccountName=staaadatahdinsight;AccountKey=nzMQVaSKaKkBOGueDpdDwWS9s/UN7GHTROB4qXySnop8xc8+5X5ulzGuNXK+9z+x/SwpA+OV4ROUkxcxSPBulA==","zeppelin.notebook.azure.share" : "zeppelin-$environment", "zeppelin.notebook.dir" : "notebook", "zeppelin.notebook.homescreen" : " ", "zeppelin.notebook.homescreen.hide" : "false", "zeppelin.notebook.public" : "false","zeppelin.notebook.s3.bucket" : "zeppelin","zeppelin.notebook.s3.user" : "user", "zeppelin.notebook.storage" : "org.apache.zeppelin.notebook.repo.AzureNotebookRepo", "zeppelin.server.addr" : "0.0.0.0","zeppelin.server.allowed.origins" : "*", "zeppelin.server.authorization.header.clear" : "false","zeppelin.server.port" : "9995","zeppelin.server.ssl.port" : "9995","zeppelin.ssl" : "false","zeppelin.ssl.client.auth" : "false","zeppelin.ssl.key.manager.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.key.manager.password","zeppelin.ssl.keystore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.keystore.password","zeppelin.ssl.keystore.path" : "conf/keystore","zeppelin.ssl.keystore.type" : "JKS","zeppelin.ssl.truststore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.truststore.password","zeppelin.ssl.truststore.path" : "conf/truststore", "zeppelin.ssl.truststore.type" : "JKS", "zeppelin.websocket.max.text.message.size" : "1024000"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/$1/

# Restart services
curl -u $USERID:$PASSWD -i -H 'X-Requested-By: ambari' -X PUT -d '{"ServiceInfo": {"state" : "INSTALLED"}}' http://headnodehost:8080/api/v1/clusters/$1/services/ZEPPELIN

curl -u $USERID:$PASSWD -i -H 'X-Requested-By: ambari' -X PUT -d '{"ServiceInfo": {"state" : "STARTED"}}'  http://headnodehost:8080/api/v1/clusters/$1/services/ZEPPELIN