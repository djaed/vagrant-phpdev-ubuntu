#
# Cookbook Name:: phpdev
# Recipe:: tools
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#
# install phpdev-tools
#
git '/home/vagrant/phpdev-tools' do
	action :checkout
	user 'vagrant'
	group 'vagrant'
	repository 'https://github.com/mp-php/phpdev-tools.git'
	reference 'master'
end

composer_project '/home/vagrant/phpdev-tools' do
	action :install
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
	user 'vagrant'
	group 'vagrant'
	repository 'https://github.com/mp-php/fuel-dbdocs.git'
	reference 'master'
	enable_submodules true
end

composer_project '/home/vagrant/fuel-dbdocs' do
	action :install
end

composer_project '/home/vagrant/fuel-dbdocs/fuel/packages/dbdocs' do
	action :install
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
