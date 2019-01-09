#!/usr/bin/env bash

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsightUtilities-v01.sh

# Check if the current  host is headnode.
if [ `test_is_headnode` == 0 ]; then
  echo  "Giraph only needs to be installed on headnode, exiting ..."
  exit 0
fi

# In case Giraph is installed, exit.
if [ -e /usr/hdp/current/giraph ]; then
    echo "Giraph is already installed, exiting ..."
    exit 0
fi
# Download Giraph binary to temporary location.
echo "Download Giraph binary to temprorary location"
download_file https://hdiconfigactions.blob.core.windows.net/giraphconfigactionv01/giraph-1.2.0.tgz /tmp/giraph-1.2.0.tgz

# Untar the Spark binary and move it to proper location.
echo "Untar binary file"
untar_file /tmp/giraph-1.2.0.tgz /usr/hdp/current
mv /usr/hdp/current/giraph-1.2.0 /usr/hdp/current/giraph

# Remove the temporary file downloaded.
echo "Remove the temporary file downloaded"
rm -f /tmp/giraph-1.2.0.tgz.tgz

# Create /example/jars directory on WASB
echo "Create /example/jars directory on WASB"
hadoop fs -mkdir -p /example/jars

# Setup environment variables as well as uploading Giraph jars to WASB.
echo "Setup environment variables as well as uploading Giraph jars to WASB."
sudo hadoop fs -copyFromLocal /usr/hdp/current/giraph/giraph-examples.jar /example/jars/

sudo hadoop fs -chmod 644 /example/jars/giraph-examples.jar
