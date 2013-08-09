#
# Cookbook Name:: phpdev
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute 'rbenv' do
	only_if {File.exists?('/etc/profile.d/rbenv.sh')}
	command '/etc/profile.d/rbenv.sh'
end

#
# apt-get update
#
execute 'apt-get' do
	command 'apt-get update'
end

#
# core
#

#
# install php and apache
#
apt_repository 'php5' do
	uri 'http://ppa.launchpad.net/ondrej/php5/ubuntu'
	distribution node['lsb']['codename']
	components ['main']
	keyserver 'keyserver.ubuntu.com'
	key 'E5267A6C'
end

apt_repository 'apache2' do
	uri 'http://ppa.launchpad.net/ondrej/apache2/ubuntu'
	distribution node['lsb']['codename']
	components ['main']
	keyserver 'keyserver.ubuntu.com'
	key 'E5267A6C'
end

%w{php5 php5-mysqlnd}.each do |p|
	package p do
		action :install
	end
end

execute 'a2enmod' do
	command 'sudo a2enmod rewrite'
end

service 'apache2' do
	supports :status => true, :restart => true, :reload => true
	action [:enable, :reload]
end

template '/etc/php5/apache2/php.ini' do
	notifies :reload, 'service[apache2]'
end

template '/etc/php5/cli/php.ini' do
end

template '/etc/apache2/apache2.conf' do
	notifies :reload, 'service[apache2]'
end

#
# install mysql
#
package 'mysql-server' do
	action :install
	notifies :run, 'execute[mysqladmin]'
end

execute 'mysqladmin' do
	action :nothing
	command 'mysqladmin password -u root ' + node['mysql']['password']
end

#
# development
#

#
# install packages
#
%w{git mongodb redis-server phpmyadmin}.each do |p|
	package p do
		action :install
	end
end

link '/var/www/phpmyadmin' do
	to '/usr/share/phpmyadmin'
end

#
# install npm packages
#
apt_repository 'nodejs' do
	uri 'http://ppa.launchpad.net/chris-lea/node.js/ubuntu'
	distribution node['lsb']['codename']
	components ['main']
	keyserver 'keyserver.ubuntu.com'
	key 'C7917B12'
end

package 'nodejs' do
	action :install
end

%w{coffee-script}.each do |p|
	execute p do
		command 'npm install -g ' + p
	end
end

#
# install gem packages
#
rbenv_ruby '1.9.3-p448' do
end

rbenv_global '1.9.3-p448' do
end

%w{fluentd jsduck}.each do |p|
	rbenv_gem p do
		action :install
	end
end

#
# install composer
#
execute 'composer' do
	not_if {File.exists?('/usr/local/bin/composer')}
	command 'curl -sS https://getcomposer.org/installer | php; mv composer.phar /usr/local/bin/composer'
end

#
# install phpdev-tools
#
git '/home/vagrant/phpdev-tools' do
	action :checkout
	notifies :run, 'execute[phpdev-tools]'
	user 'vagrant'
	group 'vagrant'
	repository 'https://github.com/mp-php/phpdev-tools.git'
	reference 'master'
end

execute 'phpdev-tools' do
	action :nothing
	user 'vagrant'
	group 'vagrant'
	command 'cd /home/vagrant/phpdev-tools; composer install'
end

link '/usr/local/bin/phpunit' do
	to '/home/vagrant/phpdev-tools/vendor/bin/phpunit'
end

link '/usr/local/bin/apigen' do
	to '/home/vagrant/phpdev-tools/vendor/bin/apigen.php'
end

link '/usr/local/bin/php-cs-fixer' do
	to '/home/vagrant/phpdev-tools/vendor/bin/php-cs-fixer'
end

#
# install fuel-dbdocs
#
git '/home/vagrant/fuel-dbdocs' do
	action :checkout
	notifies :run, 'execute[fuel-dbdocs]'
	user 'vagrant'
	group 'vagrant'
	repository 'https://github.com/mp-php/fuel-dbdocs.git'
	reference 'master'
	enable_submodules true
end

execute 'fuel-dbdocs' do
	action :nothing
	user 'vagrant'
	group 'vagrant'
	command '
		cd /home/vagrant/fuel-dbdocs; composer install;
		cd /home/vagrant/fuel-dbdocs/fuel/packages/dbdocs; composer install;
	'
end

template '/home/vagrant/fuel-dbdocs/fuel/app/config/crypt.php' do
	user 'vagrant'
	group 'vagrant'
end

directory '/home/vagrant/fuel-dbdocs/fuel/app/logs' do
	mode 0777
end

directory '/home/vagrant/fuel-dbdocs/public/dbdocs' do
	mode 0777
end

link '/var/www/dbdocs' do
	to '/home/vagrant/fuel-dbdocs/public'
end

begin
	include_recipe 'phpdev::custom'
rescue Exception => error
	# avoid Chef::Exceptions::RecipeNotFound
end