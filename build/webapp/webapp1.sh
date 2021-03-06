#!/bin/bash 

printf "\n\n\nExecuting within the container...\n\n"

# environment variable values set in .env file generated by startup script:
# APP_HOSTNAME - host identity for all instances of this app
# VAR_ID - environment variable name to fetch
# SLEEP_TIME - environment variable name to fetch

				# use follower, not conjur master
declare ENDPOINT=https://conjur_follower/api
declare LOGFILE=cc.log
declare INPUT_FILE=/data/foo

# for logfile to see whats going on
touch $LOGFILE

write_log_msg() {
	printf "$1\n"
	echo "$(date) [$(hostname)] $1" >> $LOGFILE # Left for weave scope demos
}

OLD_APP_API_KEY=""
while : ; do

		# get API key from file in shared volume
    while : ; do
	if [ -f $INPUT_FILE ]; then
		read APP_API_KEY < $INPUT_FILE
		break
		#if [[ "$APP_API_KEY" != "$OLD_APP_API_KEY" ]]; then
		   #break 
		#else
		   #sleep $SLEEP_TIME
		#fi
	else
		write_log_msg "Waiting for new API key."
		sleep $SLEEP_TIME
		continue
	fi

    done
    write_log_msg "New API key is: $APP_API_KEY"
    while : ; do
	# Login container w/ its API key, authenticate and get API key for session
	cont_login=host%2F$APP_HOSTNAME
	response=$(curl -s -k \
	 --request POST \
	 --data-binary $APP_API_KEY \
	 $ENDPOINT/authn/users/{$cont_login}/authenticate)
	CONT_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

	if [[ "$CONT_SESSION_TOKEN" == "" ]]; then
	    write_log_msg "API key is invalid..."
	    OLD_APP_API_KEY=$APP_API_KEY
	    break
	fi

	# FETCH variable value
	DB_PASSWORD=$(curl -s -k \
         --request GET \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$CONT_SESSION_TOKEN\"" \
         $ENDPOINT/variables/{$VAR_ID}/value)

	DBPASSOUT=$(echo $DB_PASSWORD | sed 's/\r\n//g' -)
  	write_log_msg "The DB Password is: $DBPASSOUT"
	sleep $SLEEP_TIME 
    done
done

exit

