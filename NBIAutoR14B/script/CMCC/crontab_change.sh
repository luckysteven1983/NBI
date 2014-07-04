#!/bin/sh

crontab -l |grep -v nediscover > newcron

crontab newcron

rm newcron

sh /etc/rc2.d/S99TAO stop
sh /etc/rc2.d/S99TAO start
