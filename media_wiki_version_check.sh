#!/bin/bash

EMAIL="admin@example.com"
SITES="www.example.info www.example2.info"

#Get Latest Version
L=`lynx -dump http://www.mediawiki.org/wiki/MediaWiki | grep -A1 "Current version" | grep "*" | cut -f2 -d "*" | cut -f2 -d" " | cut -d"]" -f 2`
for SITE in $SITES; do
        #Get Current Version
        C=`lynx -dump http://$SITE/index.php/Special:Version | grep -A3 "Installed software" | grep "MediaWiki" | cut -f2 -d"]" | cut -f2 -d" "`

        if [ $C != $L ];
                then echo -e " Site: $SITE \n Current version: $C \n Latest version:    $L \n\n Get the latest version from http://www.mediawiki.org/wiki/Download" >> /tmp/wiki.txt && `mail -s "MediaWiki for $SITE is out of Date" $EMAIL < /tmp/wiki.txt` && `rm /tmp/wiki.txt`
        fi
