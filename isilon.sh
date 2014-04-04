#!/bin/bash

# IP, port, and FQDN of server
SERVER_IP="172.16.3.10"
SERVER_PORT="8080"
HTTP="https://${SERVER_IP}:${SERVER_PORT}"
COOKIE='{
                "username": "admin",
                "password": "administrator",
                "services": ["platform","namespace"]
        }'

# Create cookiefile used for session
cookie_file_old() {
	echo '{
		"username": "admin",
		"password": "administrator",
		"services": ["platform","namespace"]
	}' > json/auth.json
}

# Create session with Isilon server by saving authorization cookie in cookiefile
connect_old() {
	curl -k --header "Content-Type: application/json" -c cookiefile \
	-X POST -d @json/auth.json ${HTTP}/session/1/session
}

connect() {
        curl -k --header "Content-Type: application/json" -c cookiefile \
        -X POST -d "${COOKIE}" ${HTTP}/session/1/session
}

connect1() {
        curl -k --header "Content-Type: application/json" -c cookiefile \
        -X POST ${HTTP}/session/1/session -d '{
                "username": "admin",
                "password": "administrator",
                "services": ["platform","namespace"]
        }'
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
echo '{
    "clients": [
        "1000072",
        "1000073",
        "1000070",
        "1000071"
    ],
    "description": "testing API Creation",
    "paths": [
        "/ifs/home/test6"
    ],
    "read_only_clients": [
        "1000070",
        "1000071"
    ],
    "read_write_clients": [
        "1000072",
        "1000073"
    ]
}' > json/create_export_${SHARE_NAME}.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/create_export_${SHARE_NAME}.json -X POST ${HTTP}/platform/1/protocols/nfs/exports
}

# Change NFS export
# $1 = ID of the share to edit
# $2 = names of clients
mod_NFS() {
	ID=$1
	CLIENTS=$2

# Create file detailing share
echo '{
    "clients": [
        "1000072",
        "1000073",
        "1000070",
        "1000071"
    ],
    "description": "testing API Creation",
    "paths": [
        "/ifs/home/test6"
    ],
    "read_only_clients": [
        "1000070"
    ],
    "read_write_clients": [
        "1000072"
    ]
}' > json/mod_export.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/mod_export.json -X PUT ${HTTP}/platform/1/protocols/nfs/exports/$1
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
	"name": "test8",
	"ntfs_acl_support": true,
	"oplocks": true,
	"path": "/ifs/home/test6",
	"permissions": [
	{
		"permission": "read",
		"permission_type": "allow",
		"trustee": {
			"id": "SID:S-1-1-0",
			"name": "Everyone",
			"type": "wellknown"
		}
	},
	{
		"permission": "full",
		"permission_type": "allow",
		"trustee": {
			"id": "SID:S-1-5-21-3786487513-3307290377-3363358357-1741",
			"name": "ITOXYGEN\\cloudred",
			"type": "group"
		}
	}
	],
	"run_as_root": [],
	"strict_flush": true,
	"strict_locking": false
}' > json/create_share.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/create_share.json -X POST ${HTTP}/platform/1/protocols/smb/shares
}

# Edit SMB share
# $1 = name of share
# $2 = names of clients
mod_SMB() {
	SHARE_NAME=$1
	CLIENTS=$2

# Create json file detailing properties to change
echo '{
	"name": "test4",
	"ntfs_acl_support": true,
	"oplocks": true,
	"path": "/ifs/home/test6",
	"permissions": [
	{
		"permission": "read",
		"permission_type": "allow",
		"trustee": {
			"id": "SID:S-1-1-0",
			"name": "Everyone",
			"type": "wellknown"
		}
	}
	],
	"run_as_root": [],
	"strict_flush": true,
	"strict_locking": false
}' > json/create_share.json

# POST share
curl -k --header "Content-Type: application/json" -b cookiefile \
-X POST -d @json/create_share.json -X PUT ${HTTP}/platform/1/protocols/smb/shares/$1
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
create_NFS)
create_NFS $2 $3
;;
mod_NFS)
mod_NFS $2 $3
;;
delete_smb)
delete_SMB $2
;;
create_SMB)
create_SMB
;;
mod_SMB)
mod_SMB $2
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

