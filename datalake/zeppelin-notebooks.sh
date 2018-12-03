#! /bin/bash
# Declare variables
USERID=$(echo -e "import hdinsight_common.Constants as Constants\nprint Constants.AMBARI_WATCHDOG_USERNAME" | python)
PASSWD=$(echo -e "import hdinsight_common.ClusterManifestParser as ClusterManifestParser\nimport hdinsight_common.Constants as Constants\nimport base64\nbase64pwd = ClusterManifestParser.parse_local_manifest().ambari_users.usersmap[Constants.AMBARI_WATCHDOG_USERNAME].password\nprint base64.b64decode(base64pwd)" | python)

## Update conf For Storage Account
curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-config","tag":"default","properties":{"zeppelin.anonymous.allowed" : "true","zeppelin.config.fs.dir" : "file:///etc/zeppelin/conf/","zeppelin.interpreter.config.upgrade" : "true","zeppelin.interpreter.connect.timeout" : "30000", "zeppelin.interpreter.dir" : "interpreter","zeppelin.interpreter.group.order" : "livy,md,sh,angular,jdbc","zeppelin.interpreters" : "org.apache.zeppelin.livy.LivySparkInterpreter,org.apache.zeppelin.livy.LivyPySparkInterpreter,org.apache.zeppelin.livy.LivySparkSQLInterpreter,org.apache.zeppelin.markdown.Markdown,org.apache.zeppelin.shell.ShellInterpreter,org.apache.zeppelin.angular.AngularInterpreter,org.apache.zeppelin.jdbc.JDBCInterpreter","zeppelin.notebook.azure.connectionString" : "DefaultEndpointsProtocol=https;AccountName=staaadatahdinsight;AccountKey=nzMQVaSKaKkBOGueDpdDwWS9s/UN7GHTROB4qXySnop8xc8+5X5ulzGuNXK+9z+x/SwpA+OV4ROUkxcxSPBulA==","zeppelin.notebook.azure.share" : "zeppelin-dev", "zeppelin.notebook.dir" : "notebook", "zeppelin.notebook.homescreen" : " ", "zeppelin.notebook.homescreen.hide" : "false", "zeppelin.notebook.public" : "false","zeppelin.notebook.s3.bucket" : "zeppelin","zeppelin.notebook.s3.user" : "user", "zeppelin.notebook.storage" : "org.apache.zeppelin.notebook.repo.AzureNotebookRepo", "zeppelin.server.addr" : "0.0.0.0","zeppelin.server.allowed.origins" : "*", "zeppelin.server.authorization.header.clear" : "false","zeppelin.server.port" : "9995","zeppelin.server.ssl.port" : "9995","zeppelin.ssl" : "false","zeppelin.ssl.client.auth" : "false","zeppelin.ssl.key.manager.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.key.manager.password","zeppelin.ssl.keystore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.keystore.password","zeppelin.ssl.keystore.path" : "conf/keystore","zeppelin.ssl.keystore.type" : "JKS","zeppelin.ssl.truststore.password" : "SECRET:zeppelin-config:1:zeppelin.ssl.truststore.password","zeppelin.ssl.truststore.path" : "conf/truststore", "zeppelin.ssl.truststore.type" : "JKS", "zeppelin.websocket.max.text.message.size" : "1024000"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/$1/

## Update conf for execution properties
curl -u $USERID:$PASSWD -H "X-Requested-By: ambari" -X PUT -d '[{"Clusters":{ "desired_config":[{"type":"zeppelin-env","tag":"default","properties":{"zeppelin_group":"zeppelin","zeppelin_log_dir":"/var/log/zeppelin","zeppelin_pid_dir":"/var/run/zeppelin","zeppelin_user":"zeppelin","zeppelin.spark.jar.dir":"/apps/zeppelin","zeppelin.server.kerberos.keytab":"/etc/security/keytabs/zeppelin.server.kerberos.keytab","zeppelin.server.kerberos.principal" :"zeppelin-aaa-hdi-dev@3ADATA.ONMICROSOFT.COM","zeppelin.executor.instances":"6","zeppelin.executor.mem":"10g","zeppelin.driver.mem":"10g","zeppelin_env_content" : "# export JAVA_HOME=\nexport JAVA_HOME={{java64_home}}\n# export MASTER=  # Spark master url. eg. spark://master_addr:7077. Leave empty if you want to use local mode.\nexport MASTER=yarn-client\nexport SPARK_YARN_JAR={{spark_jar}}\n# export ZEPPELIN_JAVA_OPTS   # Additional jvm options. for example, export ZEPPELIN_JAVA_OPTS=\"-Dspark.executor.memory=8g -Dspark.cores.max=16\"\nexport ZEPPELIN_JAVA_OPTS=\"-Dhdp.version={{full_stack_version}} -Dspark.executor.memory={{executor_mem}} -Dspark.executor.instances={{executor_instances}} -Dspark.yarn.queue={{spark_queue}}\"\n# export ZEPPELIN_MEM   # Zeppelin jvm mem options Default -Xms1024m -Xmx1024m -XX:MaxPermSize=512m\n# export ZEPPELIN_INTP_MEM   # zeppelin interpreter process jvm mem options. Default -Xms1024m -Xmx1024m -XX:MaxPermSize=512m\n# export ZEPPELIN_INTP_JAVA_OPTS  # zeppelin interpreter process jvm options.\n# export ZEPPELIN_SSL_PORT  # ssl port (used when ssl environment variable is set to true)\n\n# export ZEPPELIN_LOG_DIR  # Where log files are stored.  PWD by default.\nexport ZEPPELIN_LOG_DIR={{zeppelin_log_dir}}\n# export ZEPPELIN_PID_DIR  # The pid files are stored. ${ZEPPELIN_HOME}/run by default.\nexport ZEPPELIN_PID_DIR={{zeppelin_pid_dir}}\n# export ZEPPELIN_WAR_TEMPDIR # The location of jetty temporary directory.\n# export ZEPPELIN_NOTEBOOK_DIR # Where notebook saved\n# export ZEPPELIN_NOTEBOOK_HOMESCREEN   # Id of notebook to be displayed in homescreen. ex) 2A94M5J1Z\n# export ZEPPELIN_NOTEBOOK_HOMESCREEN_HIDE  # hide homescreen notebook from list when this value set to \"true\". default \"false\"\n# export ZEPPELIN_NOTEBOOK_S3_BUCKET # Bucket where notebook saved\n# export ZEPPELIN_NOTEBOOK_S3_ENDPOINT  # Endpoint of the bucket\n# export ZEPPELIN_NOTEBOOK_S3_USER  # User in bucket where notebook saved. For example bucket/user/notebook/2A94M5J1Z/note.json\n# export ZEPPELIN_IDENT_STRING   # A string representing this instance of zeppelin. $USER by default.\n# export ZEPPELIN_NICENESS   # The scheduling priority for daemons. Defaults to 0.\n# export ZEPPELIN_INTERPRETER_LOCALREPO   # Local repository for interpreters additional dependency loading\n# export ZEPPELIN_NOTEBOOK_STORAGE   # Refers to pluggable notebook storage class, can have two classes simultaneously with a sync between them (e.g. local and remote).\n# export ZEPPELIN_NOTEBOOK_ONE_WAY_SYNC  # If there are multiple notebook storages, should we treat the first one as the only source of truth?\n# export ZEPPELIN_NOTEBOOK_PUBLIC  # Make notebook public by default when created, private otherwise\nexport ZEPPELIN_INTP_CLASSPATH_OVERRIDES=\"{{external_dependency_conf}}\"\n\n#### Spark interpreter configuration ####\n\n## Use provided spark installation ##\n## defining SPARK_HOME makes Zeppelin run spark interpreter process using spark-submit\n##\n# export SPARK_HOME   # (required) When it is defined, load it instead of Zeppelin embedded Spark libraries\n#export SPARK_HOME={{spark_home}}\n# export SPARK_SUBMIT_OPTIONS   # (optional) extra options to pass to spark submit. eg) \"--driver-memory 512M --executor-memory 1G\".\n# export SPARK_APP_NAME   # (optional) The name of spark application.\n\n## Use embedded spark binaries ##\n## without SPARK_HOME defined, Zeppelin still able to run spark interpreter process using embedded spark binaries.\n## however, it is not encouraged when you can define SPARK_HOME\n##\n# Options read in YARN client mode\n# export HADOOP_CONF_DIR    # yarn-site.xml is located in configuration directory in HADOOP_CONF_DIR.\nexport HADOOP_CONF_DIR=/etc/hadoop/conf\n# Pyspark (supported with Spark 1.2.1 and above)\n# To configure pyspark, you need to set spark distributions path to spark.home property in Interpreter setting screen in Zeppelin GUI\n# export PYSPARK_PYTHON   # path to the python command. must be the same path on the driver(Zeppelin) and all workers.\n# export PYTHONPATH\n\nexport PYTHONPATH=\"${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.8.2.1-src.zip\"\nexport SPARK_YARN_USER_ENV=\"PYTHONPATH=${PYTHONPATH}\"\n\n## Spark interpreter options ##\n##\n# export ZEPPELIN_SPARK_USEHIVECONTEXT   # Use HiveContext instead of SQLContext if set true. true by default.\n# export ZEPPELIN_SPARK_CONCURRENTSQL   # Execute multiple SQL concurrently if set true. false by default.\n# export ZEPPELIN_SPARK_IMPORTIMPLICIT   # Import implicits, UDF collection, and sql if set true. true by default.\n# export ZEPPELIN_SPARK_MAXRESULT    # Max number of Spark SQL result to display. 1000 by default.\n# export ZEPPELIN_WEBSOCKET_MAX_TEXT_MESSAGE_SIZE   # Size in characters of the maximum text message to be received by websocket. Defaults to 1024000\n\n\n#### HBase interpreter configuration ####\n\n## To connect to HBase running on a cluster, either HBASE_HOME or HBASE_CONF_DIR must be set\n\n# export HBASE_HOME=   # (require) Under which HBase scripts and configuration should be\n# export HBASE_CONF_DIR=   # (optional) Alternatively, configuration directory can be set to point to the directory that has hbase-site.xml\n\n# export ZEPPELIN_IMPERSONATE_CMD   # Optional, when user want to run interpreter as end web user. eg) sudo -H -u ${ZEPPELIN_IMPERSONATE_USER} bash -c \nexport ZEPPELIN_LIVY_HOST_URL=http://`hostname -f`:8998\nexport CLASSPATH=$CLASSPATH:/usr/lib/hdinsight-logging/*"}, "service_config_version_note":"New config version"}]}}]' http://headnodehost:8080/api/v1/clusters/$1/


# Stop zeppelin Service
curl -u $USERID:$PASSWD -i -H 'X-Requested-By: ambari' -X PUT -d '{"ServiceInfo": {"state" : "INSTALLED"}}' http://headnodehost:8080/api/v1/clusters/$1/services/ZEPPELIN

# Tempo between 2 curl
sleep 150

# Start zeppelin Service
curl -u $USERID:$PASSWD -i -H 'X-Requested-By: ambari' -X PUT -d '{"ServiceInfo": {"state" : "STARTED"}}'  http://headnodehost:8080/api/v1/clusters/$1/services/ZEPPELIN