FROM resin/rpi-raspbian:stretch
LABEL maintainer=edgd1er

# Install prerequisites
ARG DEBIAN_FRONTEND=noninteractive
ARG NCONFDL=https://github.com/Bonsaif/new-nconf/archive/nconf-v1.4.0-final2.tar.gz
ENV MYSQL_HOST=localhost
ENV MYSQL_USER=nconf
ENV MYSQL_PASSWORD=nconf
ENV MYSQL_DATABASE=nconf

RUN [ "cross-build-start" ]

RUN apt-get -qy update && \
 apt-get -qy install vim sed wget apache2 mysql-client icinga icinga-doc nagios-nrpe-plugin ssmtp sudo supervisor\
 php7.0 php7.0-mysql libapache2-mod-php7.0 && rm -rf /var/lib/apt/lists/* && \
 sed -i "s/upload_max_filesize = 2M/upload_max_filesize = $MAX_UPLOAD/" /etc/php/7.0/apache2/php.ini && \
 sed -i "s/post_max_size = 8M/post_max_size = $MAX_UPLOAD/" /etc/php/7.0/apache2/php.ini && \
 a2enmod php7.0 && a2enmod rewrite

ADD files/apache2.conf /etc/icinga/apache2.conf
ADD files/htpasswd.users etc/icinga/htpasswd.users
ADD files/icinga.cfg /etc/icinga/icinga.cfg
ADD files/cgi.cfg /etc/icinga/cgi.cfg
ADD files/resource.cfg /etc/icinga/resource.cfg
ADD files/create_database.sh /usr/share/icinga/create_database.sh
ADD files/create_database.sql /usr/share/icinga/create_database.sql
ADD files/import_existing_nconf_into_db.sh /usr/share/icinga/import_existing_nconf_into_db.sh

# Add Rasperry-Pi logos
COPY raspberry/ /usr/share/icinga/htdocs/images/logos/raspberry/

# Add Supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Add nconf (https://github.com/Bonsaif/new-nconf/releases)
RUN  cd /var/www/html/ && mkdir nconf && \
 wget $NCONFDL -O nconf.tar.gz && \
 tar -zxf nconf.tar.gz -C nconf --strip-components=1 && rm nconf.tar.gz && \
 cd nconf && cp config.orig/* config/ && \
 sed -i 's#\$nconfdir#\"/var/www/html/nconf\"#' /var/www/html/nconf/config/nconf.php && \
 sed -i 's#/var/www/nconf#/var/www/html/nconf#' /var/www/html/nconf/config/nconf.php && \
 sed -i 's#/var/www/html/nconf/bin/nagios#/var/www/html/nconf/bin/icinga#' /var/www/html/nconf/config/nconf.php && \
 sed -i 's/\"localhost\"/\"nconf-mysql\"/' /var/www/html/nconf/config/mysql.php && \
 sed -i 's/\"NConf\"/\"nconfdb\"/' /var/www/html/nconf/config/mysql.php && \
 sed -i 's/\"nconf\"/\"nconf_user\"/' /var/www/html/nconf/config/mysql.php && \
 sed -i 's/\"link2db\"/\"changeIt\"/' /var/www/html/nconf/config/mysql.php && \
 chown www-data:www-data -R ../nconf && mkdir -p /etc/icinga/Default_collector/ /etc/icinga/global && \
 chown www-data:www-data /etc/icinga/Default_collector /etc/icinga/global && \
 chmod 744 /usr/share/icinga/*.sh

#add local deployment
ADD files/deployment.ini /var/www/html/nconf/config/deployment.ini

#copy nagios to allow nconf to validate conf
RUN cp /usr/sbin/icinga /var/www/html/nconf/bin/icinga && \
 chown www-data:www-data /var/www/html/nconf/bin/icinga

#Allow www-data to reload nagios
RUN echo "www-data ALL=NOPASSWD:/etc/init.d/icinga reload" | tee -a /etc/sudoers

# Secure SSMTP configuration
RUN mv /etc/ssmtp/ssmtp.conf /etc/icinga/ \
&& ln -snf /etc/icinga/ssmtp.conf /etc/ssmtp/ \
&& groupadd ssmtp \
&& chown :ssmtp /etc/icinga/ssmtp.conf \
&& chown :ssmtp /usr/sbin/ssmtp \
&& chmod 640 /etc/icinga/ssmtp.conf \
&& chmod g+s /usr/sbin/ssmtp

# Fix external commands
RUN chmod 2770 /var/lib/icinga/rw

# Timezone configuration
ARG TZ=Europe/Paris
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
&& echo $TZ > /etc/timezone

# Expose volumes
VOLUME ["/etc/icinga", "/var/cache/icinga", "/var/log/icinga"]

# Expose ports
EXPOSE 80

# Start services via Supervisor
ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c","/etc/supervisor/conf.d/supervisord.conf"]

RUN [ "cross-build-end" ]
