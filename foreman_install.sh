#!/bin/bash

# Install Notes: http://theforeman.org/manuals/1.1/index.html#3.2ForemanInstaller


#############
# Variables #
#############

elv=$(cat /etc/redhat-release | gawk 'BEGIN {FS="release "} {print $2}' | gawk 'BEGIN {FS="."} {print $1}')
elv="el${elv}"
arch=$(uname -m)
fqdn=$(hostname -f)

##############
# Functions  #
##############

disable_repo() {
        local conf=/etc/yum.repos.d/$1.repo
        if [ ! -e "$conf" ]; then
                echo "Yum repo config $conf not found -- exiting."
                exit 1
        else
                sudo sed -i -e 's/^enabled.*/enabled=0/g' $conf
        fi
}

enable_repo() {
        local conf=/etc/yum.repos.d/$1.repo
        if [ ! -e "$conf" ]; then
                echo "Yum repo config $conf not found -- exiting."
                exit 1
        else
		shift
                sudo sed -i -e "/\[$1\]/,/\]/ s/^enabled.*/enabled=1/" ${conf}
        fi
}

include_repo_packages() {
  	local conf=/etc/yum.repos.d/$1.repo
  	if [ ! -e "$conf" ]; then
                echo "Yum repo config $conf not found -- exiting."
                exit 1
  	else
      		shift
		pkglist=$(sed -n -e "/\[$1\]/,/\]/{ /includepkgs=/ p}" ${conf} | cut -d"=" -f2)
		if [[ -z ${pkglist} ]]; then
			pkglist="$pkglist $2"
			sudo sed -i -e "/\[$1\]/ a\includepkgs=$pkglist" ${conf}
		else
			pkglist="$pkglist $2"
			sudo sed -i -e "/\[$1\]/,/\]/ s/^includepkgs=.*/includepkgs=${pkglist}/" ${conf}
		fi
  	fi
}

enable_service() {
        sudo /sbin/chkconfig $1 on
        sudo /sbin/service $1 start
}

disable_service() {
        sudo /sbin/chkconfig $1 off
        sudo /sbin/service $1 stop
}

enable_namevirtualhosts() {
	sudo sed -i -e "/^#NameVirtualHost/ a\NameVirtualHost *:443" $1
	sudo sed -i -e "s/^#NameVirtualHost/NameVirtualHost/" $1  
	
	/etc/init.d/httpd configtest
	rc=$?
	if [ $rc -eq 0 ]; then
		/etc/init.d/httpd restart
	else
		echo "Error in Apache configure file $1"
	if
}

# Add Foreman Repository
forman_stable_version="1.1"
foreman_rpm_url="http://yum.theforeman.org/releases/${forman_stable_version}/${elv}/${arch}/foreman-release-${forman_stable_version}stable-3.${elv}.noarch.rpm"
sudo yum -y install ${foreman_rpm_url}

# Disable Foreman Repository
disable_repo foreman

# Append to EPEL approved packagelist if present, if not add includepkgs listing
# Packages from EPEL: rubygem-abstract rubygem-sinatra rubygem-treetop rubygem-uuidtools
conf="/etc/yum.repos.d/epel.repo"
pkglist=$(sed -n -e "/\[epel\]/,/\]/{ /includepkgs=/ p}" ${conf} | cut -d"=" -f2)
pkglist="rubygem-abstract rubygem-sinatra rubygem-treetop rubygem-uuidtools ${pkglist}"
sudo sed -i -e "/\[epel\]/,/\]/ s/^includepkgs=.*/includepkgs=${pkglist}/" ${conf}

# Include just required packages from FOREMAN
include_repo_packages foreman foreman "rubygem-mysql rubygem-rbvmomi rubygem-trollop rubygem-mysql2 rubygem-hirb-unicode rubygem-formatador rubygems rubygem-rake rubygem-rack rubygem-wirb rubygem-will_paginate rubygem-virt rubygem-unicode-display_width rubygem-tzinfo rubygem-thor rubygem-actionmailer rubygem-actionpack rubygem-activemodel rubygem-activerecord rubygem-activeresource rubygem-activesupport rubygem-acts_as_audited rubygem-ancestry rubygem-apipie-rails rubygem-are rubygem-audit rubygem-audited-activerecord rubygem-awesome_print rubygem-builder rubygem-bundler rubygem-erubis rubygem-excon rubygem-fog rubygem-foremancli rubygem-formatado rubygem-hirb rubygem-hirb-unicod rubygem-i18n rubygem-jquery-rails rubygem-mail rubygem-mime-types rubygem-multi_json rubygem-net-ldap rubygem-net-scp rubygem-net-ssh rubygem-nokogiri rubygem-oauth rubygem-pg rubygem-polyglot rubygem-rabl rubygem-rack-mount rubygem-rack-test rubygem-rails rubygem-railties rubygem-rbovirt rubygem-rdoc rubygem-rest-client rubygem-ruby-hmac rubygem-ruby-libvirt rubygem-ruby2ruby rubygem-ruby_parser rubygem-safemode rubygem-scoped_search rubygem-sexp_processor rubygem-arel rubygem-audited foreman foreman-proxy foreman-cli foreman-libvirt foreman-ovirt foreman-console foreman-postgresql foreman-ec2 foreman-vmware foreman-mysql foreman-mysql2"

# Enable FOREMAN Repository
enable_repo foreman foreman

# Install foreman packages
# Packages from FOREMAN: rubygems rubygem-rake rubygem-rack rubygem-wirb rubygem-will_paginate rubygem-virt rubygem-unicode-display_width rubygem-tzinfo rubygem-thor rubygem-actionmailer rubygem-actionpack rubygem-activemodel rubygem-activerecord rubygem-activeresource rubygem-activesupport rubygem-acts_as_audited rubygem-ancestry rubygem-apipie-rails rubygem-are rubygem-audit rubygem-audited-activerecord rubygem-awesome_print rubygem-builder rubygem-bundler rubygem-erubis rubygem-excon rubygem-fog rubygem-foremancli rubygem-formatado rubygem-hirb rubygem-hirb-unicod rubygem-i18n rubygem-jquery-rails rubygem-mail rubygem-mime-types rubygem-multi_json rubygem-net-ldap rubygem-net-scp rubygem-net-ssh rubygem-nokogiri rubygem-oauth rubygem-pg rubygem-polyglot rubygem-rabl rubygem-rack-mount rubygem-rack-test rubygem-rails rubygem-railties rubygem-rbovirt rubygem-rdoc rubygem-rest-client rubygem-ruby-hmac rubygem-ruby-libvirt rubygem-ruby2ruby rubygem-ruby_parser rubygem-safemode rubygem-scoped_search rubygem-sexp_processor
sudo yum --enablerepo=foreman --enablerepo=epel -y install foreman foreman-proxy foreman-cli foreman-libvirt foreman-ovirt foreman-console foreman-postgresql foreman-ec2 foreman-vmware foreman-mysql foreman-mysql2

# Setup Foreman to use Passenger and Apache
cat >> /etc/httpd/conf.d/foreman.conf << EOF
<VirtualHost *:80>
    ServerName ${fqdn}
    DocumentRoot /usr/share/foreman/public
    RailsAutoDetect On
    AddDefaultCharset UTF-8
</VirtualHost>
<VirtualHost *:443>
    ServerName ${fqdn}
    RailsAutoDetect On
    RailsEnv production
    DocumentRoot /usr/share/foreman/public
    # Use puppet certificates for SSL
    SSLEngine On
    SSLCertificateFile /var/lib/puppet/ssl/certs/${fqdn}.pem
    SSLCertificateKeyFile /var/lib/puppet/ssl/private_keys/${fqdn}.pem
    SSLCertificateChainFile /var/lib/puppet/ssl/certs/ca.pem
    SSLCACertificateFile /var/lib/puppet/ssl/certs/ca.pem
    SSLVerifyClient optional
    SSLOptions +StdEnvVars
    SSLVerifyDepth 3
</VirtualHost>
EOF

# Enable NameVirtualHost in Apache
enable_namevirtualhosts /etc/httpd/conf/httpd.conf
