#!/usr/bin/env bash
#
# create tables ofr nconf to operate
#

mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h$MYSQL_HOST -D$MYSQL_DATABASE  < /usr/share/icinga/create_database.sql

#generate mysql.php files with env values ( needed, because perl script get conf from php files, as i understood )
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

