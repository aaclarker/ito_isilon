#!/bin/bash

# IP, port, and FQDN of server
SERVER_IP="172.16.3.10"
SERVER_PORT="8080"
HTTP="https://${SERVER_IP}:${SERVER_PORT}"

# Create cookiefile used for session
cookie_file() {
echo '{
"username": "admin",
"password": "administrator",
"services": ["platform","namespace"]
}' > auth.json
}

# Create session with Isilon server by saving authorization cookie in cookiefile
connect() {
curl -k --header "Content-Type: application/json" -c cookiefile \
-X POST -d @auth.json ${HTTP}/session/1/session
}

# Disconnect session
disconnect() {
curl -k -b @cookiefile -X DELETE ${HTTP}/session/1/session?isisessid
}

# Return session ID
check_session() {
curl -k -b @cookiefile ${HTTP}/session/1/session?isisessid
}

#############################
# NFS Section
#############################

# Set Active Directory domain for NFS
set_domain() {

echo '{
"name": "itoxygen.com",
"user": "linuxauth",
"password": "Kew33naw"
}' > domain.json

curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @domain.json -X POST ${HTTP}/platform/1/auth/providers/ads
}

# Create NFS export
# $1 = name of share
# $2 = names of clients
create_NFS() {
SHARE_NAME=$1
CLIENTS=$2

# Create file detailing share
echo "{
\"clients\": [\"${CLIENTS}\"],
\"description\": \"testing API Creation\",
\"paths\": [\"/ifs/${SHARE_NAME}\"],
\"read_only_clients\": [\"\"],
\"read_write_clients\": [\"\"]
}" > create_export_${SHARE_NAME}.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @create_export_${SHARE_NAME}.json -X POST ${HTTP}/platform/1/protocols/nfs/exports
}

# List all NFS shares
list_NFS() {
curl -k -b @cookiefile ${HTTP}/platform/1/protocols/nfs/exports
}

# Delete specified NFS share
# $1 = id of share to delete
delete_NFS() {
curl -k -b @cookiefile -X DELETE ${HTTP}/platform/1/protocols/nfs/exports/$1
}

#############################
# SMB Section
#############################

# List SMB shares
list_SMB() {
curl -k -b @cookiefile ${HTTP}/platform/1/protocols/smb/shares
}

# Create NFS export
# $1 = name of share
# $2 = names of clients
create_SMB() {
SHARE_NAME=$1
CLIENTS=$2

# Create json file detailing share
echo '{
"id": "1",
"path": "/example/",
"name": "example",
"description": "example",
}' > create_export_${SHARE_NAME}.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @create_export_${SHARE_NAME}.json -X POST ${HTTP}/platform/1/protocols/smb/shares
}


# Running the script
# cookie_file;
# connect;
# check_session;
# create_NFS test4 test_user;
# list_NFS;
# delete_NFS 2;
# list_NFS;
# list_SMB;

# disconnect;

testing() {
curl -k -b @cookiefile ${HTTP}/platform/1/auth/providers/summary
}


test() {
echo Received: $1
echo Received: $2
echo Received: $3
echo Received: $4
}

case "$1" in
        connect)
       		cookie_file
	        connect
	        ;;
	disconnect)
		disconnect
		;;
	check_session)
		check_session
		;;
	delete_nfs)
		delete_NFS $2
		;;
        delete_smb)
                delete_SMB $2
                ;;
	test)
		test "$@"
		;;
	testing)
		set_domain
		;;
	*)
		echo "Please enter a valid command"
		exit 1
esac

