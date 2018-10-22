# ########################################################################################
# Credit: Most of this setup script came from Yusaku Sako (u39kun).
#         See https://github.com/u39kun/ambari-util/blob/master/ldap/setup-ldap-server.sh.
# ########################################################################################
yum clean all

yum install openldap-servers openldap-clients -y

LDAP_SERVER=`hostname -f	`
CWD=`pwd`

cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

chown -R ldap:ldap /var/lib/ldap

cd /etc/openldap

mv slapd.d slapd.d.original

chkconfig slapd on

cp ldap.conf ldap.conf.original

cat > /etc/openldap/slapd.conf << EOFDELIM
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#
include 	/etc/openldap/schema/core.schema
include 	/etc/openldap/schema/cosine.schema
include 	/etc/openldap/schema/inetorgperson.schema
include 	/etc/openldap/schema/nis.schema

# Added for policy
include /etc/openldap/schema/ppolicy.schema

# Allow LDAPv2 client connections.  This is NOT the default.
allow bind_v2

# Do not enable referrals until AFTER you have a working directory
# service AND an understanding of referrals.
#referral   ldap://root.openldap.org

pidfile 	/var/run/openldap/slapd.pid
argsfile	/var/run/openldap/slapd.args

# Load dynamic backend modules:
# modulepath	/usr/lib64/openldap

# Modules available in openldap-servers-overlays RPM package
# Module syncprov.la is now statically linked with slapd and there
# is no need to load it here
# moduleload accesslog.la
# moduleload auditlog.la
# moduleload denyop.la
# moduleload dyngroup.la
# moduleload dynlist.la
# moduleload lastmod.la
# moduleload pcache.la

moduleload ppolicy.la
moduleload memberof.la

# moduleload refint.la
# moduleload retcode.la
# moduleload rwm.la
# moduleload smbk5pwd.la
# moduleload translucent.la
# moduleload unique.la
# moduleload valsort.la
 
# modules available in openldap-servers-sql RPM package:
# moduleload back_sql.la
 
# The next three lines allow use of TLS for encrypting connections using a
# dummy test certificate which you can generate by changing to
# /etc/pki/tls/certs, running "make slapd.pem", and fixing permissions on
# slapd.pem so that the ldap user or group can read it.  Your client software
# may balk at self-signed certificates, however.
# TLSCACertificateFile /etc/pki/tls/certs/ca-bundle.crt
# TLSCertificateFile /etc/pki/tls/certs/slapd.pem
# TLSCertificateKeyFile /etc/pki/tls/certs/slapd.pem
 
# Sample security restrictions
#   Require integrity protection (prevent hijacking)
#   Require 112-bit (3DES or better) encryption for updates
#   Require 63-bit encryption for simple bind
# security ssf=1 update_ssf=112 simple_bind=64
 
# Sample access control policy:
#   Root DSE: allow anyone to read it
#   Subschema (sub)entry DSE: allow anyone to read it
#   Other DSEs:
#   	Allow self write access
#   	Allow authenticated users read access
#   	Allow anonymous users to authenticate
#   Directives needed to implement policy:
# access to dn.base="" by * read
# access to dn.base="cn=Subschema" by * read
# access to *
#   by self write
#   by users read
#   by anonymous auth
#
# if no access controls are present, the default policy
# allows anyone and everyone to read anything but restricts
# updates to rootdn.  (e.g., "access to * by * read")
#
# rootdn can always read and write EVERYTHING!
 
#######################################################################
# ldbm and/or bdb database definitions
#######################################################################
 
database  bdb
suffix  "dc=apache,dc=org"
rootdn  "cn=ldap_admin,dc=apache,dc=org"
rootpw  {SSHA}ckC+F39YJhds/Rn2TRZqH8Y++7+avorS

# Enable memberOf attribute
overlay memberof

# PPolicy Configuration
overlay ppolicy
ppolicy_default "cn=default,ou=policies,dc=apache,dc=org"
ppolicy_use_lockout
ppolicy_hash_cleartext

# The database directory MUST exist prior to running slapd AND
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.
directory   /var/lib/ldap

# Indices to maintain for this database
index objectClass  eq,pres
index ou,cn,mail,surname,givenname  eq,pres,sub
index uidNumber,gidNumber,loginShell  eq,pres
index uid,memberUid  eq,pres,sub
index nisMapName,nisMapEntry  eq,pres,sub
EOFDELIM

cat > /etc/openldap/ppolicy.ldif << EOFDELIM
dn: ou = policies,dc=apache,dc=org
objectClass: organizationalUnit
objectClass: top
ou: policies

# default, policies, example.com
dn: cn=default,ou=policies,dc=apache,dc=org
objectClass: top
objectClass: pwdPolicy
objectClass: person
cn: default
sn: dummy value
pwdAttribute: userPassword
pwdMaxAge: 7516800
pwdExpireWarning: 14482463
pwdMinLength: 2
pwdMaxFailure: 10
pwdLockout: TRUE
pwdLockoutDuration: 60
pwdMustChange: FALSE
pwdAllowUserChange: FALSE
pwdSafeModify: FALSE
EOFDELIM

service slapd start

# artbitary sleep to wait long enough for slapd to make the rest of the script work...
sleep 5

ldapsearch -h localhost -D "cn=ldap_admin,dc=apache,dc=org" -w yoursecretpassword -b "dc=apache,dc=org" -s sub "objectclass=*"

cp $CWD/users_groups.ldif /etc/openldap/users_groups.ldif

ldapadd -x -D "cn=ldap_admin,dc=apache,dc=org" -w yoursecretpassword  -f users_groups.ldif

cat > /etc/openldap/ldap.conf << EOFDELIM
URI ldap://${LDAP_SERVER}:389
BASE dc=apache,dc=org
TLS_CACERTDIR /etc/openldap/certs
EOFDELIM
