#!/usr/bin/env bash
#
# import existing nconf generated files into empty database
#

collector=/etc/icinga/Default_collector
global=/etc/icinga/global

simulation=""
[[ "${simulation}" == "$1" ]] && simulation=" -s"

echo "please, troncate tables before importing"

cd /var/www/html/nconf/
bin/add_items_from_nagios.pl -c timeperiod -f ${global}/timeperiods.cfg ${simulation}
bin/add_items_from_nagios.pl -c misccommand -f ${global}/misccommands.cfg ${simulation}
bin/add_items_from_nagios.pl -c checkcommand -f ${global}/checkcommands.cfg ${simulation}
bin/add_items_from_nagios.pl -c contact -f ${global}/contacts.cfg ${simulation}
bin/add_items_from_nagios.pl -c contactgroup -f ${global}/contactgroups.cfg ${simulation}
bin/add_items_from_nagios.pl -c host-template -f ${global}/host_templates.cfg ${simulation}
bin/add_items_from_nagios.pl -c host -f ${collector}/parent-hosts.cfg ${simulation}
bin/add_items_from_nagios.pl -c host -f ${collector}/hosts.cfg ${simulation}
bin/add_items_from_nagios.pl -c hostgroup -f ${collector}/hostgroups.cfg ${simulation}
bin/add_items_from_nagios.pl -c host-dependency -f ${collector}/host_dependencies.cfg ${simulation}
bin/add_items_from_nagios.pl -c service-template -f ${collector}/service_templates.cfg ${simulation}
bin/add_items_from_nagios.pl -c service -f ${collector}/services.cfg ${simulation}
bin/add_items_from_nagios.pl -c advanced-service -f ${collector}/advanced-services.cfg ${simulation}
bin/add_items_from_nagios.pl -c servicegroup -f ${collector}/servicegroups.cfg ${simulation}
bin/add_items_from_nagios.pl -c service-dependency -f ${collector}/service_dependencies.cfg ${simulation}