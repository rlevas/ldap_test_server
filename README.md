# LDAP Test Server

Installs OpenLDAP and a set of users and groups that can be used for testing connectivity with an 
LDAP server. 

The OpenLDAP server is set to include the `memberof` module/overlay so that the `memberOf` attribute 
can be returned when querying for users. For Example:
```
[root@c7401 ~]# ldapsearch -h localhost -D "cn=ldap_admin,dc=apache,dc=org" -w yoursecretpassword -b "uid=admin,ou=people,ou=dev,dc=apache,dc=org" dn memberOf
# extended LDIF
#
# LDAPv3
# base <uid=admin,ou=people,ou=dev,dc=apache,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: dn memberOf
#

# admin, people, dev, apache.org
dn: uid=admin,ou=people,ou=dev,dc=apache,dc=org
memberOf: cn=admninistrator,ou=groups,ou=dev,dc=apache,dc=org
memberOf: cn=user,ou=groups,ou=dev,dc=apache,dc=org

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1
```

## Installation
The LDAP test server installation script currently runs on RedHat/CentOS-based systems. It has been 
tested on CentOS 6.4 and CentOS 7.4; but should work on other 6.x and 7.x versions. 
 
To install the LDAP test server, **execute `./setup_ldap_test_server.sh`** as root or some other 
privileged user.  

The script performs the following steps:
* Installs the OpenLDAP server and clients using `yum`
* Creates the slapd.conf file
* Creates the password policy LDIF file
* Starts the OpenLDAP server
* Creates the initial directory with users and groups (see user_groups.ldif)

## Users and Groups
#### The LDAP server administrator
* DN: `cn=ldap_admin,dc=apache,dc=org`
* Password: `yoursecretpassword`

#### The users
* Admin
  * DN: `uid=admin,ou=people,ou=dev,dc=apache,dc=org`
  * Username: `admin`
  * Password: `admin-password`
* Guest
  * DN: `uid=guest,ou=people,ou=dev,dc=apache,dc=org`
  * Username: `guest`
  * Password: `guest-password`
* Sam
  * DN: `uid=sam,ou=people,ou=dev,dc=apache,dc=org`
  * Username: `sam`
  * Password: `sam-password`
* Tom
  * DN: `uid=tom,ou=people,ou=dev,dc=apache,dc=org`
  * Username: `tom`
  * Password: `tom-password`
  
#### The groups
* User
  * DN: `cn=user,ou=groups,ou=dev,dc=apache,dc=org`
  * Members: `admin`, `sam`, `tom`
* Administrator
  * DN: `cn=administrator,ou=groups,ou=dev,dc=apache,dc=org`
  * Members: `admin`

## Customization
The base DN (`dc=apache,dc=org`), LDAP administrator username (`ldap_admin`), and LDAP 
administrator password (`yoursecretpassword`) may be changed by editing 
`setup_ldap_test_server.sh` and changing the desired variables before executing it:

```
BASE_DN='dc=apache,dc=org'
...
LDAP_ADMIN_NAME='ldap_admin'
LDAP_ADMIN_PASSWORD='yoursecretpassword'
```

## Credit
The setup script is based off of the scripts created by Yusaku Sako (u39kun) in 
[ambari-util](https://github.com/u39kun/ambari-util) repo. 
See https://github.com/u39kun/ambari-util/tree/master/ldap.
 
