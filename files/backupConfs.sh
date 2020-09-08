#!/bin/sh

# configuration de l'utilisateur MySQL et de son mot de passe
DB_USER="$MYSQL_USER"
DB_PASS="$MYSQL_PASSWORD"
# configuration de la machine hébergeant le serveur MySQL
DB_HOST="$MYSQL_HOST"
#if not defined then it's 120 days
REMOVE_OLDER_THAN=${REMOVE_OLDER_THAN:-120}

# sous-chemin de destination
OUTDIR=$(date +%Y-%m-%d)
# création de l'arborescence
mkdir -p /var/archives/$OUTDIR

#Functions
backupBdd() {
  # récupération de la liste des bases
  DATABASES=$(MYSQL_PWD=$DB_PASS mysql -u $DB_USER -e "SHOW DATABASES;" | tr -d "| " | grep -v -e Database -e _schema -e mysql)
  # boucle sur les bases pour les dumper
  for DB_NAME in $DATABASES; do
    MYSQL_PWD=$DB_PASS mysqldump -u $DB_USER --single-transaction --skip-lock-tables $DB_NAME -h $DB_HOST >/var/archives/$OUTDIR/$DB_NAME.sql
  done
  # boucle sur les bases pour compresser les fichiers
  for DB_NAME in $DATABASES; do
    gzip -9 /var/archives/$OUTDIR/$DB_NAME.sql
  done
}

backupIcingaFiles() {
  tar -zcf /var/archives/$OUTDIR/icinga.tar.gz -C /etc/icinga Default_collector global msmtprc $(ls /etc/icinga/*.cfg)
}
#Main
backupBdd
# archivage
backupIcingaFiles
#clean old archives
find /var/archives/ -type d -mtime +${REMOVE_OLDER_THAN} -exec ls -al {} \; -delete

