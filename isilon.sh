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
}' > json/auth.json
}

# Create session with Isilon server by saving authorization cookie in cookiefile
connect() {
curl -k --header "Content-Type: application/json" -c cookiefile \
-X POST -d @json/auth.json ${HTTP}/session/1/session
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

# Set Active Directory domain
set_domain() {

echo '{
"name": "itoxygen.com",
"user": "linuxauth",
"password": "Kew33naw"
}' > json/domain.json

curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/domain.json -X POST ${HTTP}/platform/1/auth/providers/ads
}

get_zones() {
curl -k -b @cookiefile ${HTTP}/platform/1/zones
}

create_zone() {

echo '{
"name": "Active-Directory-Zone",
"auth_providers": ["lsa-activedirectory-provider:itoxygen.com"]
}' > json/domain.json

curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/domain.json -X POST ${HTTP}/platform/1/zones
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
}" > json/create_export_${SHARE_NAME}.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/create_export_${SHARE_NAME}.json -X POST ${HTTP}/platform/1/protocols/nfs/exports
}

# List all NFS shares
list_NFS() {
curl -k -b @cookiefile ${HTTP}/platform/1/protocols/nfs/exports
}

# Get specific NFS share
get_NFS() {
curl -k -b @cookiefile ${HTTP}/platform/1/protocols/nfs/exports/$1
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

get_SMB() {
curl -k -b @cookiefile ${HTTP}/platform/1/protocols/smb/shares/$1
}

# Create SMB export
# $1 = name of share
# $2 = names of clients
create_SMB() {
SHARE_NAME=$1
CLIENTS=$2

# Create json file detailing share
echo '{
"name" : "test7",
"ntfs_acl_support" : true,
"oplocks" : true,
"path" : "/ifs/home/test6",
"permissions" :
[
{
"permission" : "read",
"permission_type" : "allow",
"trustee" :
{
"id" : "SID:S-1-1-0",
"name" : "Everyone",
"type" : "wellknown"
}
}
],
"run_as_root" : [],
"strict_flush" : true,
"strict_locking" : false
}' > json/create_export_4.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/create_export_4.json -X POST ${HTTP}/platform/1/protocols/smb/shares
}

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
	list_SMB)
		list_SMB
		;;
	get_SMB)
		get_SMB $2
		;;
	list_NFS)
		list_NFS
		;;
	get_NFS)
		get_NFS $2
		;;
	delete_smb)
		delete_SMB $2
		;;
	create_SMB)
		create_SMB
		;;
	testing)
		# set_domain
		create_zone
		get_zones
		;;
	*)
		echo "Please enter a valid command"
		exit 1
esac

