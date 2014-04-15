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

#############################
# Connecting Section
#############################

# Create cookiefile used for session
cookie_file() {
	COOKIE='{
		"username": "admin",
		"password": "administrator",
		"services": ["platform","namespace"]
	}'
}

# Connect and generate session cookie
connect() {
	curl -k --header "Content-Type: application/json" -c cookiefile \
	-X POST -d "$COOKIE" ${HTTP}/session/1/session
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
# Authentication Section
#############################

# Set Active Directory domain
set_domain() {

	DOMAIN='{
		"name": "itoxygen.com",
		"user": "linuxauth",
		"password": "Kew33naw"
	}'

	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$DOMAIN" -X POST ${HTTP}/platform/1/auth/providers/ads
}

# Return existing zones
get_zones() {
	curl -k -b @cookiefile ${HTTP}/platform/1/zones
}

# Create user zone from Active Directory Domain
create_zone() {

	ZONE='{
		"name": "Active-Directory-Zone",
		"auth_providers": ["lsa-activedirectory-provider:itoxygen.com"]
	}'

	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$ZONE" -X POST ${HTTP}/platform/1/zones
}

#############################
# Quota Management
#############################
create_quota() {

	QUOTA='{
		"enforced": true,
		"include_snapshots": false,
		"path": "/ifs/home/test6",
		"thresholds_include_overhead": false,
		"type": "directory"

	}'
	# curl -k -b @cookiefile ${HTTP}/platform/1/auth/providers/summary
	# curl -k -b @cookiefile ${HTTP}/platform/1/quota/quotas-summary
	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$QUOTA" -X POST ${HTTP}/platform/1/quota/quotas
}

#############################
# NFS Section
#############################

# List all NFS shares
list_NFS() {
	curl -k -b @cookiefile ${HTTP}/platform/1/protocols/nfs/exports
}

# Get specific NFS share details
# $1 = ID of share
get_NFS() {
	curl -k -b @cookiefile ${HTTP}/platform/1/protocols/nfs/exports/$1
}

# Create NFS export
create_NFS() {

	# Create file detailing share
	SHARE='{
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
	}'

	# POST share
	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$SHARE" -X POST ${HTTP}/platform/1/protocols/nfs/exports
}

# Change NFS export
# $1 = ID of the share to edit
mod_NFS() {
	ID=$1

	# Create file detailing share
	SHARE='{
		"clients": [
		"1000072",
		"1000070",
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
	}'

	# POST share
	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$SHARE" -X PUT ${HTTP}/platform/1/protocols/nfs/exports/$1
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
create_SMB() {
	SHARE_NAME=$1

	# Create json file detailing share
	SHARE='{
		"name": "${SHARE_NAME}",
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
	}'

	# POST share
	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$SHARE" -X POST ${HTTP}/platform/1/protocols/smb/shares
}

# Edit SMB share
# $1 = name of share
mod_SMB() {
	SHARE_NAME=$1

	# Create json file detailing properties to change
	SHARE='{
		"name": "${SHARE_NAME}",
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
	}'

	# POST share
	curl -k --header "Content-Type: application/json" -b cookiefile \
	-X POST -d "$SHARE" -X PUT ${HTTP}/platform/1/protocols/smb/shares/$1
}

#
#
# Control which function is called on runtime
#
#
case "$1" in
#############################
# Authentication Section
#############################
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
set_domain)
	set_domain
	;;
	set
create_zone)
	create_zone
	;;
get_zones)
	get_zones
	;;
#############################
# Quota Section
#############################
create_quota)
	create_quota
	;;
#############################
# NFS Section
#############################
list_NFS)
	list_NFS
	;;
get_NFS)
	get_NFS $2
	;;
create_NFS)
	create_NFS
	;;
mod_NFS)
	mod_NFS $2 $3
	;;
delete_nfs)
	delete_NFS $2
	;;
#############################
# SMB Section
#############################
list_SMB)
	list_SMB
	;;
get_SMB)
	get_SMB $2
	;;
create_SMB)
	create_SMB
	;;
mod_SMB)
	mod_SMB $2 $3
	;;
delete_smb)
	delete_SMB $2
	;;
# Catch any invalid input
*)
	echo "Please enter a valid command"
	exit 1
esac
