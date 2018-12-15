#!/usr/bin/env bash
#
# create tables ofr nconf to operate
#

createDatabase(){
    echo creating database tables
    mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE  < /usr/share/icinga/create_database.sql
}


#generate mysql.php files with env values ( needed, because perl script get conf from php files, as i understood )
generateMysql(){
    echo settings credentials to acccess nconf database
cat > /var/www/html/nconf/config/mysql.php <<EOF
<?php
##
## MySQL config
##

#
# Main MySQL connection parameters
#
define('DBHOST', "$MYSQL_HOST");
define('DBNAME', "$MYSQL_DATABASE");
define('DBUSER', "$MYSQL_USER");
define('DBPASS', "$MYSQL_PASSWORD");

?>
EOF
}

setRights(){
    echo setting rights for cache/icinga directory
    chown nagios:www-data /var/cache/icinga/
    chmod 744 /var/cache/icinga/

}

## Main

res=$(mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE -Be 'show tables;')
ret=$?

if [ $ret -ne 0 -o $(echo $res | wc -w) -lt 7 ]; then
    createDatabase
    generateMysql
fi
setRights