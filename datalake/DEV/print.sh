#!/usr/bin/env bash

echo "Action script for installing MRS on HDI..."

#versions
MRO_FILE_VERSION=3.3

#filenames
MRS_FILENAME=MRS_Linux.data
R_PROBE_FILENAME=RProbe.py
RO16N_PROBE_FILENAME=RO16NProbe.py
ELAPSED_TIME_LOG=/tmp/installRServerElapsedTime.log

#storage with CDN enabled
#the pattern we're using here is, http://mrshdiprod.azureedge.net/{mrs release}/{mrs build number}.{version number of all other packages}
BLOB_STORAGE=https://mrshdiprod.azureedge.net/mrs-hdi-binaries-9-1-1/109.0
SAS="?sv=2014-02-14&sr=c&sig=iaTLInyWxNzp%2FD%2Bmo2AKvqU%2FrU0kqFnxqKv8JkfQ5h8%3D&st=2017-04-21T07%3A00%3A00Z&se=2020-06-02T07%3A00%3A00Z&sp=r"

#hostname identifiers
HEADNODE=^hn
EDGENODE=^ed
WORKERNODE=^wn
ZOOKEEPERNODE=^zk

#misc
USERNAME=""
IS_HEADNODE=0
IS_EDGENODE=0
R_LIBRARY_DIR=/usr/lib64/microsoft-r/"$MRO_FILE_VERSION"/lib64/R/library
RPROFILE_PATH=/usr/lib64/microsoft-r/"$MRO_FILE_VERSION"/lib64/R/etc/Rprofile.site
REVOHADOOPENVVARS_PATH=/usr/lib64/microsoft-r/"$MRO_FILE_VERSION"/hadoop/RevoHadoopEnvVars.site
TRACKR_OPTIN_PATH=/usr/lib64/microsoft-r/"$MRO_FILE_VERSION"/lib64/R/.optIn
PROBES_CONFIG=`python -c "from pkg_resources import resource_filename; print resource_filename('hdinsight_probes', 'probes_config.json')"`
PROBES_PYTHON_DIR=`python -c "import os, hdinsight_probes.probes; print os.path.dirname(hdinsight_probes.probes.__file__)"`
R_LOG_PYTHON="$R_LIBRARY_DIR"/RevoScaleR/pythonScripts/common/logScaleR.py

#retry
MAXATTEMPTS=3

#set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

#main function
main()
{
    #if there is any failure in the script, retry the entire script
	retry start
}

start()
{
	SECONDS=0
	
	if [[ -f /var/opt/microsoft/RSERVER_DEPLOYMENT_FINISHED ]]; then 
		echo "RSERVER is already existing, finishing ..."
		echo "Total elapsed time = $SECONDS seconds"
		echo "Finished"
		exit 0
	fi
	
	executor downloadMRS
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor unpackMRS
	if [[ $? -ne 0 ]]; then return 1; fi

	executor checkHDFS
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor installMRS
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor installMML
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor createSymbolLinkForDeployR
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor configureRWithJava
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor updateDependencies
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor configureSSHUser
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor testR
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor determineNodeType
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor setupTelemetry
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor setupHealthProbe
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor writeClusterDefinition
	if [[ $? -ne 0 ]]; then return 1; fi
	
	executor autoSparkSetting
	if [[ $? -ne 0 ]]; then return 1; fi
    
	executor applyPatches
	if [[ $? -ne 0 ]]; then return 1; fi

	executor removeTempFiles
	if [[ $? -ne 0 ]]; then return 1; fi

	echo "Total elapsed time = $SECONDS seconds" | tee -a $ELAPSED_TIME_LOG
	logElapsedTime
	echo "Finished"
	exit 0
}

waitDpkgLock()
{
	local n=1
	local max=18
	local delay=10
	echo "Resolve dpkg lock issue before retry::-------------------------------"
	while true; do
		if [[ $n -lt $max ]]; then
			echo "Running rm -f /var/lib/dpkg/lock"
			sudo lsof /var/lib/dpkg/lock
			if [[ "$?" -eq 0 ]]; then
				echo "dpkg was locked, another process is using it, wait 10 seconds"
			elif [[ "$?" -eq 1 ]]; then
				echo "dpkg is not locked, continuing"
				break
			fi
			((n++))
			sleep $delay;
		else
			echo "dpkg is still locked after waiting for 3 mins, try to unlock the dpkg..."
			echo "::-------------------------------------------------------"
			echo "Running rm -f /var/lib/dpkg/lock and dpkg --configure -a"            
			sudo rm -f /var/lib/dpkg/lock 
			sudo dpkg --configure -a
			echo "::-------------------------------------------------------"
			echo "Deleting Microsoft.RServer.WebNode/db and Microsoft.RServer.WebNode/logs"
			sudo rm -rf /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/db
			sudo rm -rf /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/logs
			sudo rm -rf /var/lib/dpkg/updates/000*
			sudo apt-get clean
			sleep $delay;  
			break
		fi
	done
}

retry()
{
	#retries to install if there is a failure
	
	ATTMEPTNUM=1
	RETRYINTERVAL=2
	RETVAL_RETRY=0

	"$1"
    if [ "$?" != "0" ]
    then
        RETVAL_RETRY=1
	fi

	while [ $RETVAL_RETRY -ne 0 ]; do
		if (( ATTMEPTNUM == MAXATTEMPTS ))
		then
			echo "Attempt $ATTMEPTNUM failed. no more attempts left."
			return 1
		else
			echo "Attempt $ATTMEPTNUM failed! Retrying in $RETRYINTERVAL seconds..."

            waitDpkgLock

			sleep $(( RETRYINTERVAL ))
			let ATTMEPTNUM=ATTMEPTNUM+1

			echo "::-------------------------------------------------------"
			echo "Running rm -f /var/lib/dpkg/lock and dpkg --configure -a"            
			sudo rm -f /var/lib/dpkg/lock 
			sudo dpkg --configure -a

			echo "::-------------------------------------------------------"
			echo "Deleting Microsoft.RServer.WebNode/db and Microsoft.RServer.WebNode/logs"
			sudo rm -rf /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/db
			sudo rm -rf /usr/lib64/microsoft-r/rserver/o16n/9.1.0/Microsoft.RServer.WebNode/logs
            
			"$1"
			if [ "$?" != "0" ]
			then
				RETVAL_RETRY=1
			else
				return 0
			fi
		fi
	done
	
	return 0
}

executor()
{
	#wrapper function that calculates time to execute another function

	RETVAL_EXE=0
	START=`date +%s%N`
	
	#execute the function passed as a parameter
	"$1"
	if [ "$?" != "0" ]
	then
		RETVAL_EXE=1
	fi

	END=`date +%s%N`
	ELAPSED=`awk 'BEGIN {printf("%.3f", ('$END' - '$START') / 1000000000)}'`
	echo "Elapsed time for $1 = $ELAPSED seconds" | tee -a $ELAPSED_TIME_LOG

	return $RETVAL_EXE
}

function download_file
{
    srcurl=$1;
    destfile=$2;
    overwrite=$3;

    if [ "$overwrite" = false ] && [ -e $destfile ]; then
        return;
    fi

    sudo wget --timeout=900 -O $destfile $srcurl;
    return $?
}

downloadMRS()
{
	echo "-------------------------------------------------------"
	echo "Download MRS files..."
	echo "-------------------------------------------------------"

	download_file "$BLOB_STORAGE/$R_PROBE_FILENAME$SAS" /tmp/$R_PROBE_FILENAME
	download_file "$BLOB_STORAGE/$RO16N_PROBE_FILENAME$SAS" /tmp/$RO16N_PROBE_FILENAME
}

unpackMRS()
{
	echo "-------------------------------------------------------"
	echo "Unpack MRS ..."
	echo "-------------------------------------------------------"

	if [ -f /var/opt/microsoft/"$MRS_FILENAME" ]
	then
		gpg --passphrase v6k0Y1133Osuf8C -d /var/opt/microsoft/"$MRS_FILENAME" | tar xzvf - -C /tmp
	else
		echo "MRS not downloaded"
		return 1
	fi
}

checkHDFS()
{
	echo "-------------------------------------------------------"
	echo "Checking HDFS..."
	echo "-------------------------------------------------------"
	
	hadoop dfsadmin -report
	
    n=0
    until [ $n -ge 5 ]
    do
        hadoop fs -test -d /
        if [[ "$?" != "0" ]]
        then
            n=$[$n+1]
            echo "HDFS seems not accessible, retrying in 40 seconds..."
            sleep 40
        else
        	break
        fi
    done
	
	if [[ $n -eq 5 ]]
	then
		echo "HDFS not accessible..."
		return 1
	fi
}

installMRS()
{
	echo "-------------------------------------------------------"
	echo "Install MRS ..."
	echo "-------------------------------------------------------"

	RETURN=0
	cd /tmp/MRS_Linux
	chmod 777 install.sh
	./install.sh -ampsi

	if [ $? -eq 0 ]
	then
		echo "MRS install finished"
	else
		echo "MRS install failed"
		RETURN=1
	fi

	rm -f $TRACKR_OPTIN_PATH

	echo "Print installer log ..."
	for f in /tmp/MRS_Linux/logs/*; do echo $f; cat $f; done

	rm -rf /tmp/MRS_Linux/logs/

	if [ "$RETURN" -ne 0 ]
	then
		return 1
	fi

	echo "Configure R env variables for MRS..."
	if [ -f $RPROFILE_PATH ]
	then
		sed -i.bk -e "1s@^@Sys.setenv(SPARK_HOME=\"/usr/hdp/current/spark2-client\")\n@" $RPROFILE_PATH
		sed -i -e "1s@^@Sys.setenv(SPARK_MAJOR_VERSION=2)\n@" $RPROFILE_PATH
		sed -i -e "1s@^@Sys.setenv(AZURE_SPARK=1)\n@" $RPROFILE_PATH
	else
		echo "$RPROFILE_PATH does not exist"
		return 1
	fi
}

installMML()
{
	echo "-------------------------------------------------------"
	echo "Install MML ..."
	echo "-------------------------------------------------------"

	if [ -d /var/opt/microsoft/MicrosoftML ]
	then
		cp -r /var/opt/microsoft/MicrosoftML ${R_LIBRARY_DIR}
	else
		echo "MML Package not downloaded"
		return 1
	fi
}

createSymbolLinkForDeployR()
{
	echo "-------------------------------------------------------"
	echo "Create symbol link for DeployR..."
	echo "-------------------------------------------------------"

	cd /lib/x86_64-linux-gnu
	ln -sf libpcre.so.3 libpcre.so.0
	ln -sf liblzma.so.5 liblzma.so.0

	cd /usr/lib/x86_64-linux-gnu
	ln -sf libicui18n.so.55 libicui18n.so.36
	ln -sf libicuuc.so.55 libicuuc.so.36
	ln -sf libicudata.so.55 libicudata.so.36
}

configureRWithJava()
{
	echo "-------------------------------------------------------"
	echo "Configure R for use with Java..."
	echo "-------------------------------------------------------"

	ln -sf /usr/bin/realpath /usr/local/bin/realpath

	echo "Configure R for use with Java..."
	R CMD javareconf
}

updateDependencies()
{
	echo "-------------------------------------------------------"
	echo "Update dependencies..."
	echo "-------------------------------------------------------"

	apt-get install -y -f
}

configureSSHUser()
{
	echo "-------------------------------------------------------"
	echo "Configuration for the specified 'ssh' user..."
	echo "-------------------------------------------------------"

	if [ $IS_HEADNODE == 1 ] || [ $IS_EDGENODE == 1 ]
	then
		USERNAME=$( grep :Ubuntu: /etc/passwd | cut -d ":" -f1)

		if [ $IS_EDGENODE == 1 ]
		then
			$(hadoop fs -test -d /user/RevoShare/$USERNAME)
			if [[ "$?" != "0" ]]
			then
				echo "Creating HDFS directory..."
				hadoop fs -mkdir /user/RevoShare/$USERNAME
				hadoop fs -chmod 777 /user/RevoShare/$USERNAME
			fi
		fi

		if [ ! -d /var/RevoShare/$USERNAME ]
		then
			echo "Creating local directory..."
			mkdir -p /var/RevoShare/$USERNAME
			chmod 777 /var/RevoShare/$USERNAME
		fi
	fi
}

testR()
{
	#Run a small set of R commands to give some confidence that the install went ok
	echo "-------------------------------------------------------"
	echo "Test R..."
	echo "-------------------------------------------------------"

	R --no-save --no-restore -q -e 'options(mds.telemetry=0);d=rxDataStep(iris)'  2>&1 >> /tmp/rtest_inst.log
	if [ $? -eq 0 ]
	then
		echo "R installed properly"
	else
		echo "R not installed properly"
		return 1
	fi

	echo "-------------------------------------------------------"
	echo "Test Rscript..."
	echo "-------------------------------------------------------"

	Rscript --no-save --no-restore -e 'options(mds.telemetry=0);d=rxDataStep(iris)'  2>&1 >> /tmp/rtest_inst.log
	if [ $? -eq 0 ]
	then
		echo "Rscript installed properly"
	else
		echo "Rscript not installed properly"
		return 1
	fi
}

determineNodeType()
{
	echo "-------------------------------------------------------"
	echo "Determine node type..."
	echo "-------------------------------------------------------"

	if hostname | grep "$HEADNODE" 2>&1 > /dev/null
	then
		IS_HEADNODE=1
	fi

	if hostname | grep $EDGENODE 2>&1 > /dev/null
	then
		IS_EDGENODE=1
	fi
}

setupTelemetry()
{
	# We only want to install telemetry on the headnode or edgenode
	if [ $IS_HEADNODE == 1 ] || [ $IS_EDGENODE == 1 ]
	then
		echo "-------------------------------------------------------"
		echo "Setup telemetry and logging..."
		echo "-------------------------------------------------------"

		MDS_OPTIONS='options(mds.telemetry=1)\noptions(mds.logging=1)\noptions(mds.target=\"azurehdi\")\n\n'

		if [ -f $RPROFILE_PATH ]
		then
			if ! grep 'options(mds' $RPROFILE_PATH 2>&1 > /dev/null
			then
				sed -i.bk -e "1s/^/$MDS_OPTIONS/" $RPROFILE_PATH
				sed -i 's/\r$//' $RPROFILE_PATH
			fi
		else
			echo "$RPROFILE_PATH does not exist"
			return 1
		fi
	fi
}

setupHealthProbe()
{
	# We only want to install the health probe on the headnode or edgenode
	if [ $IS_EDGENODE == 1 ]
	then
		echo "-------------------------------------------------------"
		echo "Setup the R-Server HDI health probe..."
		echo "-------------------------------------------------------"

		if [ -f $PROBES_CONFIG ]
		then
			if ! grep 'RProbe.RProbe' $PROBES_CONFIG 2>&1 > /dev/null
			then
				echo "Modify the probes config file..."

				cp "$PROBES_CONFIG" "$PROBES_CONFIG".bk

				#define the probe config entry
				read -d '' REVOPROBE <<-"EOF"
[\\n
           {\\n
               \"name\" : \"RProbe\",\\n
               \"version\" : \"0.1\",\\n
               \"script\" : \"hdinsight_probes.probes.RProbe.RProbe\",\\n
               \"interval_seconds\" : 300,\\n
               \"timeout_seconds\" : 60,\\n
               \"node_types\" : \[\"headnode\"\]\\n
           },\\n
           {\\n
               \"name\" : \"RO16NProbe\",\\n
               \"version\" : \"0.1\",\\n
               \"script\" : \"hdinsight_probes.probes.RO16NProbe.RO16NProbe\",\\n
               \"interval_seconds\" : 300,\\n
               \"timeout_seconds\" : 60,\\n
               \"node_types\" : \[\"headnode\"\]\\n
           },
EOF

				# Remove all other probe configurations on the edgenode
				if [ $IS_EDGENODE == 1 ]
				then
					REVOPROBE=$(echo "$REVOPROBE"|sed 's/headnode/edgenode/')
				fi

				REVOPROBE=$(echo "$REVOPROBE"|tr '\n' ' ')

				# Insert the RevoProbe configuration
				sed -i -e "0,/\[/s//${REVOPROBE}/" $PROBES_CONFIG

				# Get rid of any remaining '\r' characters
				sed -i 's/\r$//' $PROBES_CONFIG

				if [ -d $PROBES_PYTHON_DIR ]
				then
					if [ -f /tmp/"$R_PROBE_FILENAME" ]
					then
						cd $PROBES_PYTHON_DIR
						mv /tmp/"$R_PROBE_FILENAME" .
						pycompile "$R_PROBE_FILENAME"
						chmod 755 "$R_PROBE_FILENAME"
					fi

					if [ -f /tmp/"$RO16N_PROBE_FILENAME" ]
					then
						cd $PROBES_PYTHON_DIR
						mv /tmp/"$RO16N_PROBE_FILENAME" .
						pycompile "$RO16N_PROBE_FILENAME"
						chmod 755 "$RO16N_PROBE_FILENAME"
					fi

					echo "Restart the probes service..."
					service hdinsight-probes stop
					service hdinsight-probes start

					if [ -z "$(service hdinsight-probes status | grep 'active (running)' 2>&1)" ]
					then
						echo "Probes service is not in 'running' status"
						return 1
					fi

					COUNTER=0
					while [  $COUNTER -lt 15 ]; do
						if [ ! -z "$(less /var/log/hdinsight-probes/hdinsight-probes.out | grep 'MdsLogger.py' | grep 'Successfully' 2>&1)" ]
						then
							break
						fi
						let COUNTER=COUNTER+1
						sleep 1s
					done

					if [ $COUNTER -eq 60 ]
					then
						echo "Probes service cannot start properly"
						return 1
					fi
				else
					echo "$PROBES_PYTHON_DIR does not exist"
					return 1
				fi
			fi
		else
			echo "$PROBES_CONFIG does not exist"
			return 1
		fi
	fi
}

writeClusterDefinition()
{
	echo "-------------------------------------------------------"
	echo "Writing cluster definition to HDFS..."
	echo "-------------------------------------------------------"

	NODETYPE="unknown"
	if hostname | grep $HEADNODE 2>&1 > /dev/null
	then
		NODETYPE="headnode"
	fi

	if hostname | grep $EDGENODE 2>&1 > /dev/null
	then
		NODETYPE="edgenode"
	fi

	if hostname | grep $WORKERNODE 2>&1 > /dev/null	
	then
		NODETYPE="workernode"
	fi

	if hostname | grep $ZOOKEEPERNODE 2>&1 > /dev/null
	then
		NODETYPE="zookeepernode"
	fi

	CORES=""
	if grep 'cpu cores' /proc/cpuinfo 2>&1 > /dev/null
	then
		CORES=$(grep 'cpu cores' /proc/cpuinfo | head -1 | cut -d ':' -f2 | tr -d '[:blank:]')
	else
		echo "Cannot get node cpu settings"
		return 1
	fi

	MEMORY=""
	if grep 'cpu cores' /proc/cpuinfo 2>&1 > /dev/null
	then
		MEMORY=$(grep 'MemTotal' /proc/meminfo |  cut -d ':' -f2 | tr -d '[:blank:]')
		MEMORY=${MEMORY::-2}
	else
		echo "Cannot get node memory settings"
		return 1
	fi

	HOSTNAME=`hostname`
	NODEINFO="$NODETYPE;$MEMORY;$CORES"
	echo $NODEINFO > /tmp/$HOSTNAME

	$(hadoop fs -test -d /cluster-info)
	if [[ "$?" != "0" ]]
	then
		echo "Creating HDFS directory for cluster-info..."
		hadoop fs -mkdir /cluster-info
	fi

	if [ -f /tmp/$HOSTNAME ]
	then
		echo "Creating HDFS hostname file..."
		hadoop fs -copyFromLocal -f /tmp/$HOSTNAME /cluster-info
		rm -rf /tmp/$HOSTNAME
	else
		echo "/tmp/$HOSTNAME does not exist"
	fi
}

autoSparkSetting()
{
	if [ $IS_EDGENODE == 1 ]
	then
		echo "-------------------------------------------------------"
		echo "Setup spark executor settings..."
		echo "-------------------------------------------------------"
		HADOOP_CONFDIR=$(hadoop envvars | grep HADOOP_CONF_DIR | cut -d "'" -f 2)
		YARN_MEMORY=$(xmllint --xpath "/configuration/property[name[text()='yarn.nodemanager.resource.memory-mb']]/value/text()" ${HADOOP_CONFDIR}/yarn-site.xml)
		VCORES=$(xmllint --xpath "/configuration/property[name[text()='yarn.nodemanager.resource.cpu-vcores']]/value/text()" ${HADOOP_CONFDIR}/yarn-site.xml)
		CORES_AVL=$(($VCORES-3))
		EXECUTOR_MEMORY=$(($((YARN_MEMORY-3000))*2/5))
		CORE_NUM=$(($((YARN_MEMORY-3000))*8/35000))
		TMPCORE=$(($CORE_NUM<$CORES_AVL?$CORE_NUM:$CORES_AVL))
		EXECUTOR_CORES=$(($TMPCORE>1?$TMPCORE:1))
		EXECUTOR_NUM=$(grep -c -v '^ *$' ${HADOOP_CONFDIR}/slaves)

		SPARK_OPTIONS='RevoScaleR::rxOptions(spark.executorCores='${EXECUTOR_CORES}',spark.executorMem=\"'${EXECUTOR_MEMORY}'m\",spark.executorOverheadMem=\"'${EXECUTOR_MEMORY}'m\",spark.numExecutors='$EXECUTOR_NUM')\n'

		if [ -f $RPROFILE_PATH ]
		then
			if ! grep 'options(executor' $RPROFILE_PATH 2>&1 > /dev/null
			then
				sed -i.bk -e "$ a $SPARK_OPTIONS" $RPROFILE_PATH
			fi
		else
			echo "$RPROFILE_PATH does not exist"
			return 1
		fi
	fi
}

applyPatches()
{
    echo "-------------------------------------------------------"
    echo "Apply patches..."
    echo "-------------------------------------------------------"

    if [ -f $REVOHADOOPENVVARS_PATH ]
    then
        JAVA_OPTS="export JAVA_TOOL_OPTIONS=-Xss4m"
        if ! grep 'export JAVA_TOOL_OPTIONS=' $REVOHADOOPENVVARS_PATH 2>&1 > /dev/null
        then
            sed -i.bk -e "$ a $JAVA_OPTS" $REVOHADOOPENVVARS_PATH
        fi
    else
        echo "$REVOHADOOPENVVARS_PATH does not exist"
        return 1
        
    fi
}

removeTempFiles()
{
	echo "-------------------------------------------------------"
	echo "Remove MRS temp files..."
	echo "-------------------------------------------------------"

	if [ -f /var/opt/microsoft/"$MRS_FILENAME" ]
	then
		rm -f /var/opt/microsoft/"$MRS_FILENAME"
	fi

	if [ -d /tmp/MRS_Linux ]
	then
		rm -rf /tmp/MRS_Linux
	fi
	
	echo "Generating RSERVER_DEPLOYMENT_FINISHED file"
	echo "Succeeded" | sudo tee /var/opt/microsoft/RSERVER_DEPLOYMENT_FINISHED
}

logElapsedTime()
{
	echo "-------------------------------------------------------"
	echo "Log Elapsed time..."
	echo "-------------------------------------------------------"

	if [ -f $R_LOG_PYTHON ]
	then
			python $R_LOG_PYTHON -m $ELAPSED_TIME_LOG -f 1 -p 1 2>&1 > /dev/null
	else
			echo "$R_LOG_PYTHON does not exist"
	fi
}

#call the main function
main "$@"
