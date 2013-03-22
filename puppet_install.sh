#!/bin/bash

# Install Puppet 3.x on Centos 6.x

#############
# Variables #
#############

elv=$(cat /etc/redhat-release | gawk 'BEGIN {FS="release "} {print $2}' | gawk 'BEGIN {FS="."} {print $1}')
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


# Stop/Disable SELinux (Premissive Mode)
sudo /usr/sbin/setenforce 0

# Stop/Disable IPTables v4/v6
disable_service iptables
disable_service ip6tables

# Add Puppet Labs YUM repository
cat >> /etc/yum.repos.d/puppetlabs.repo << EOF
[puppetlabs]
name=Puppet Labs Packages
baseurl=http://yum.puppetlabs.com/el/\$releasever/products/\$basearch/
enabled=1
gpgcheck=1
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
EOF

# Disable Puppet Labs YUM repository
disable_repo puppetlabs

# Add EPEL YUM repository
epel_rpm_url=http://dl.fedoraproject.org/pub/epel/$elv/$arch
sudo wget -4 -r -l1 --no-parent -A 'epel-release*.rpm' $epel_rpm_url
sudo yum -y --nogpgcheck localinstall dl.fedoraproject.org/pub/epel/$elv/$arch/epel-*.rpm
sudo rm -rf dl.fedoraproject.org

# Disable EPEL YUM repository
disable_repo epel

# Install Ruby prerequisites
# Packages from EPEL: ruby-augeas rubygem-json
sudo yum --enablerepo=epel -y install ruby ruby-lib ruby-rdoc ruby-augeas ruby-irb ruby-shadow rubygem-json rubygems libselinux-ruby 

# Install Puppet Server
# Packages from PUPPETLABS: puppet puppet-server facter hiera
sudo yum --enablerepo=puppetlabs --enablerepo=epel -y install puppet puppet-server

# Start the puppetmaster service to create SSL certificate
/etc/init.d/puppetmaster start

# Stop/Disable the puppet master service as it will be controled via passenger.
disable_service puppetmaster

# Install Passenger Apache Module ( Because Webbrick...really?)
# Packages from EPEL: mod_passenger rubygem-passenger rubygem-passenger-native rubygem-passenger-navtive-libs libev rubygem-fastthread rubygem-rack
sudo yum --enablerepo=puppetlabs --enablerepo=epel install rubygem-passenger rubygem-passenger-native rubygem-passenger-native-libs mod_passenger

# Configure the Apache conf.d for passenger
cat >> /etc/httpd/conf.d/puppetmaster.conf << EOF
# you probably want to tune these settings
PassengerHighPerformance on
PassengerMaxPoolSize 12
PassengerPoolIdleTime 1500
# PassengerMaxRequests 1000
PassengerStatThrottleRate 120
RackAutoDetect Off
RailsAutoDetect Off

Listen 8140

<VirtualHost *:8140>
        SSLEngine on
        SSLProtocol -ALL +SSLv3 +TLSv1
        SSLCipherSuite ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP

        SSLCertificateFile      /var/lib/puppet/ssl/certs/${fqdn}.pem
        SSLCertificateKeyFile   /var/lib/puppet/ssl/private_keys/${fqdn}.pem
        SSLCertificateChainFile /var/lib/puppet/ssl/ca/ca_crt.pem
        SSLCACertificateFile    /var/lib/puppet/ssl/ca/ca_crt.pem
        # If Apache complains about invalid signatures on the CRL, you can try disabling
        # CRL checking by commenting the next line, but this is not recommended.
        SSLCARevocationFile     /var/lib/puppet/ssl/ca/ca_crl.pem
        SSLVerifyClient optional
        SSLVerifyDepth  1
        SSLOptions +StdEnvVars

        RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
        RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
        RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

        DocumentRoot /etc/puppet/rack/public/
        RackBaseURI /
        RailsEnv production
        <Directory /etc/puppet/rack/>
                Options None
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>
</VirtualHost>
EOF

# Create Ruby Rack within Puppet directory strucutre for ease of management.
sudo mkdir /etc/puppet/rack
sudo mkdir /etc/puppet/rack/public
sudo mkdir /etc/puppet/rack/tmp
sudo cp /usr/share/puppet/ext/rack/files/config.ru /etc/puppet/rack
sudo chown puppet:root /etc/puppet/rack/config.ru
sudo chmod 644 /etc/puppet/rack/config.ru

# Install Apache SSL (mod_ssl)
sudo yum install mod_ssl

# Start/Enable apache service (httpd)
enable_service httpd

# Include just required packages from EPEL
# include_repo_packages <repo conf file> <repo name> <"package list">
include_repo_packages epel epel "mod_passenger rubygem-passenger rubygem-passenger-native rubygem-passenger-navtive-libs libev rubygem-fastthread rubygem-rack ruby-augeas rubygem-json"

# Enable EPEL Repository
# enable_repo <repo conf file> <repo name>
enable_repo epel epel

# Include just required packages from PUPPETLABS
include_repo_packages puppetlabs puppetlabs "puppet puppet-server facter hiera"

# Enable PUPPETLABS Repository
enable_repo puppetlabs puppetlabs



