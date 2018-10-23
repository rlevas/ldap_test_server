#!/bin/bash
# ########################################################################################
# Credit: Most of this setup script came from Yusaku Sako (u39kun).
#         See https://github.com/u39kun/ambari-util/blob/master/ldap/setup-ldap-server.sh.
# ########################################################################################

yum clean all
yum install openldap-servers openldap-clients -y

CWD=`pwd`
OPENLDAP_CONFIG_DIR='/etc/openldap'
OPENLDAP_RUN_DIR='/var/run/openldap'
OPENLDAP_LIB_DIR='/var/lib/ldap'
OPENLDAP_SLAPPASSWD='/sbin/slappasswd'
LDAP_SERVER=`hostname -f`
LDAP_ADMIN_NAME='ldap_admin'
LDAP_ADMIN_PASSWORD='yoursecretpassword'
LDAP_ADMIN_PASSWORD_HASH=`${OPENLDAP_SLAPPASSWD} -s ${LDAP_ADMIN_PASSWORD}`
BASE_DN='dc=apache,dc=org'

prompt_user()
{
	value=""
    until [ ! -z  ${value} ]; do
		echo -n "${1}"
		if [ ! -z ${2} ]; then
			echo -n " (${2})"
		fi
		echo -n ": "
		read value

		if [ -z ${value} ]; then
        	value=${2}
		fi
	done
}

replace_variables()
{
	sed -i "s:LDAP_SERVER:${LDAP_SERVER}:" ${1}
	sed -i "s:BASE_DN:${BASE_DN}:" ${1}
	sed -i "s:OPENLDAP_CONFIG_DIR:${OPENLDAP_CONFIG_DIR}:" ${1}
	sed -i "s:OPENLDAP_RUN_DIR:${OPENLDAP_RUN_DIR}:" ${1}
	sed -i "s:OPENLDAP_LIB_DIR:${OPENLDAP_LIB_DIR}:" ${1}
	sed -i "s:LDAP_ADMIN_NAME:${LDAP_ADMIN_NAME}:" ${1}
	sed -i "s:LDAP_ADMIN_PASSWORD_HASH:${LDAP_ADMIN_PASSWORD_HASH}:" ${1}
	sed -i "s:LDAP_ADMIN_PASSWORD:${LDAP_ADMIN_PASSWORD}:" ${1}
}

echo "##################################"
echo "Installation Options"
echo "##################################"
prompt_user "LDAP Server administrator username" ${LDAP_ADMIN_NAME}
LDAP_ADMIN_NAME=${value}

prompt_user "LDAP Server administrator password" ${LDAP_ADMIN_PASSWORD}
LDAP_ADMIN_PASSWORD=${value}
LDAP_ADMIN_PASSWORD_HASH=`${OPENLDAP_SLAPPASSWD} -s ${LDAP_ADMIN_PASSWORD}`

echo "##################################"
echo "Setting up LDAP server"
echo "##################################"
cp /usr/share/openldap-servers/DB_CONFIG.example ${OPENLDAP_LIB_DIR}/DB_CONFIG

chown -R ldap:ldap ${OPENLDAP_LIB_DIR}

mv ${OPENLDAP_CONFIG_DIR}/slapd.d ${OPENLDAP_CONFIG_DIR}/slapd.d.original

chkconfig slapd on

cp ${OPENLDAP_CONFIG_DIR}/ldap.conf ${OPENLDAP_CONFIG_DIR}/ldap.conf.original

cp ${CWD}/slapd.conf ${OPENLDAP_CONFIG_DIR}/slapd.conf
replace_variables ${OPENLDAP_CONFIG_DIR}/slapd.conf

cp ${CWD}/ppolicy.ldif ${OPENLDAP_CONFIG_DIR}/ppolicy.ldif
replace_variables ${OPENLDAP_CONFIG_DIR}/ppolicy.ldif

service slapd start

# artbitary sleep to wait long enough for slapd to make the rest of the script work...
sleep 5

ldapsearch -h localhost -D "cn=${LDAP_ADMIN_NAME},${BASE_DN}" -w ${LDAP_ADMIN_PASSWORD} -b "${BASE_DN}" -s sub "objectclass=*"

cp $CWD/users_groups.ldif ${OPENLDAP_CONFIG_DIR}/users_groups.ldif
replace_variables ${OPENLDAP_CONFIG_DIR}/users_groups.ldif

ldapadd -x -D "cn=${LDAP_ADMIN_NAME},${BASE_DN}" -w ${LDAP_ADMIN_PASSWORD}  -f ${OPENLDAP_CONFIG_DIR}/users_groups.ldif

cp $CWD/ldap.conf ${OPENLDAP_CONFIG_DIR}/ldap.conf
replace_variables ${OPENLDAP_CONFIG_DIR}/ldap.conf
