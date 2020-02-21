#!/bin/bash

# Fill /etc/timesketch/timesketch.conf with valid data
function prepare {
	# Sleep while postgres is setting up
	sleep 10

	# Set SECRET_KEY in /etc/timesketch/timesketch.conf if it isn't already set
	if grep -q "SECRET_KEY = '<KEY_GOES_HERE>'" /etc/timesketch/timesketch.conf; then
		OPENSSL_RAND=$( openssl rand -base64 32 )
		# Using the pound sign as a delimiter to avoid problems with / being output from openssl
		sed -i 's#SECRET_KEY = \x27<KEY_GOES_HERE>\x27#SECRET_KEY = \x27'$OPENSSL_RAND'\x27#' /etc/timesketch/timesketch.conf
	fi

	# Set up the Postgres connection
	if [ $POSTGRES_USER ] && [ $POSTGRES_PASSWORD ] && [ $POSTGRES_ADDRESS ] && [ $POSTGRES_PORT ]; then
		sed -i 's#postgresql://<USERNAME>:<PASSWORD>@localhost#postgresql://'$POSTGRES_USER':'$POSTGRES_PASSWORD'@'$POSTGRES_ADDRESS':'$POSTGRES_PORT'#' /etc/timesketch/timesketch.conf
	else
		# Log an error since we need the above-listed environment variables
		echo "Please pass values for the POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_ADDRESS, and POSTGRES_PORT environment variables"
		exit 1
	fi

	# Set up the Redis connection for Celery broker
	if [ $REDIS_ADDRESS ] && [ $REDIS_PORT ]; then
	        # Turn on the upload feature
	        sed -i 's#UPLOAD_ENABLED = False#UPLOAD_ENABLED = True#' /etc/timesketch/timesketch.conf
	        sed -i 's#UPLOAD_FOLDER = \x27/tmp\x27#UPLOAD_FOLDER = \x27/timelines\x27#' /etc/timesketch/timesketch.conf
	
	        sed -i 's#redis://127.0.0.1:6379#redis://'$REDIS_ADDRESS':'$REDIS_PORT'#g' /etc/timesketch/timesketch.conf
	else
	        # Log an error since we need the above-listed environment variables
	        echo "Please pass values for the REDIS_ADDRESS and REDIS_PORT environment variables"
	        exit 1
	fi

	# Set up the Elastic connection
	if [ $ELASTIC_ADDRESS ] && [ $ELASTIC_PORT ]; then
		sed -i 's#ELASTIC_HOST = \x27127.0.0.1\x27#ELASTIC_HOST = \x27'$ELASTIC_ADDRESS'\x27#' /etc/timesketch/timesketch.conf
		sed -i 's#ELASTIC_PORT = 9200#ELASTIC_PORT = '$ELASTIC_PORT'#' /etc/timesketch/timesketch.conf
	else
		# Log an error since we need the above-listed environment variables
		echo "Please pass values for the ELASTIC_ADDRESS and ELASTIC_PORT environment variables"
		exit 1
	fi

	# Set up the Neo4j connection
	if [ $NEO4J_ADDRESS ] && [ $NEO4J_PORT ] && [ $NEO4J_USERNAME ] && [ $NEO4J_PASSWORD ]; then
        sed -i 's#GRAPH_BACKEND_ENABLED = False#GRAPH_BACKEND_ENABLED = True#' /etc/timesketch/timesketch.conf
		sed -i 's#NEO4J_HOST = \x27127.0.0.1\x27#NEO4J_HOST = \x27'$NEO4J_ADDRESS'\x27#' /etc/timesketch/timesketch.conf
		sed -i 's#NEO4J_PORT = 9200#NEO4J_PORT = '$NEO4J_PORT'#' /etc/timesketch/timesketch.conf
		sed -i 's#NEO4J_USERNAME = \x27neo4j\x27#NEO4J_USERNAME = '$NEO4J_USERNAME'#' /etc/timesketch/timesketch.conf
		sed -i 's#NEO4J_PASSWORD = \x27NEO4J_PASSWORD\x27#NEO4J_PASSWORD = '$NEO4J_PASSWORD'#' /etc/timesketch/timesketch.conf
	else
		# Log a warning since we may need the above-listed environment variables
		echo "Please pass values for the NEO4J_ADDRESS, NEO4J_PORT, NEO4J_USERNAME and NEO4J_PASSWORD environment variables if you want graph support"
	fi
}

# Run the container the default way
if [ "$1" = 'timesketch' ]; then
	prepare

	# Run the Timesketch server (without SSL)
	exec `tsctl runserver -h 0.0.0.0 -p 5000`

# Run celery worker
elif [ "$1" = 'worker' ]; then
	prepare
	sleep 5
	exec `celery -A timesketch.lib.tasks worker --uid nobody --autoscale=10,1 --loglevel=info`

# Run a custom command on container start
else
	exec "$@"
fi
