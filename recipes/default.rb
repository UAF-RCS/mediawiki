#
# Cookbook Name:: mediawiki
# Recipe:: default
#
# Copyright (C) 2015 UAF-RCS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'chef-vault::default'
# include_recipe 'apache2::default'
# include_recipe 'apache2::mod_ssl'
# include_recipe 'apache2::mod_php'
include_recipe 'php::ini'
include_recipe 'acme::default'

apache2_install 'default_install' do
  notifies :restart, 'apache2_service[httpd]'
end

apache2_module 'php' do
  notifies :reload, 'apache2_service[httpd]'
end

apache2_module 'ssl' do
  notifies :reload, 'apache2_service[httpd]'
end

if platform_family?('rhel')
  if node['platform_version'].to_f <= 8.0
    package 'epel-release' do
      action :install
    end
    remote_file "#{Chef::Config[:file_cache_path]}/remi-release-8.rpm" do
      source 'http://rpms.remirepo.net/enterprise/remi-release-8.rpm'
      owner 'root'
      group 'root'
      mode '0744'
      action :create
    end
    dnf_package 'remi-release-8.rpm' do
      source "#{Chef::Config[:file_cache_path]}/remi-release-8.rpm"
      action :install
    end
    bash 'Install php' do
      code <<-EOH
        dnf -y install dnf-plugins-core
        dnf module -y reset php
        dnf module -y install php:remi-7.3
      EOH
    end
    # packages = %w(php-xml php-pecl-apc php-intl git ImageMagick)
    packages = %w(php73-php-xml php73-php php73-php-pecl-apcu php-intl git ImageMagick)
  elsif node['platform_version'].to_f >= 9.0
    package 'epel-release' do
      action :install
    end
    remote_file "#{Chef::Config[:file_cache_path]}/remi-release-9.rpm" do
      source 'http://rpms.remirepo.net/enterprise/remi-release-9.rpm'
      owner 'root'
      group 'root'
      mode '0744'
      action :create
    end
    dnf_package 'remi-release-9.rpm' do
      source "#{Chef::Config[:file_cache_path]}/remi-release-9.rpm"
      action :install
    end
    bash 'Install php' do
      code <<-EOH
        dnf -y install dnf-plugins-core
        dnf module -y reset php
        dnf module -y install php:remi-8.2
      EOH
    end
    # packages = %w(php-xml php-pecl-apc php-intl git ImageMagick)
    packages = %w(php82-php-xml php82-php php82-php-pecl-apcu php-intl git ImageMagick)
  end
elsif platform_family?('debian')
  packages = %w(php-xml-parser php-apc php5-intl git ImageMagick)
end

packages.each do |pkg|
  package pkg do
    action :install
  end
end

# Grab settings from vault
node.default['mediawiki']['wgDBuser'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgDBuser']
node.default['mediawiki']['wgDBpassword'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgDBpassword']
node.default['mediawiki']['admin_user'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['admin_user']
node.default['mediawiki']['admin_user_password'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['admin_password']
node.default['mediawiki']['wgSecretKey'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgSecretKey']
node.default['mediawiki']['wgLDAPProxyAgent'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgLDAPProxyAgent']
node.default['mediawiki']['wgLDAPProxyAgentPassword'] = chef_vault_item("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgLDAPProxyAgentPassword']

directory '/var/chef/files' do
  action :create
  recursive true
end

remote_file '/var/chef/files/mediawiki.tar.gz' do
  source node['mediawiki']['package_url']
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

archive_file '/var/chef/files/mediawiki.tar.gz' do
  destination "#{node['mediawiki']['web_dir']}/mediawiki-#{node['mediawiki']['full_version']}"
  owner node['mediawiki']['owner']
  group node['mediawiki']['group']
  strip_components 1
  overwrite false
  action :extract
end

link "#{node['mediawiki']['install_dir']}" do
  to "#{node['mediawiki']['web_dir']}/mediawiki-#{node['mediawiki']['full_version']}"
  link_type :symbolic
end

if node['mediawiki']['local_database'] == true
  if node['mediawiki']['wgDBtype'] == 'postgres'
    if platform_family?('rhel')
      package 'php-pgsql' do
        action :install
      end
    elsif platform_family?('debian')
      package 'php5-pgsql' do
        action :install
      end
    end

    postgresql_install 'Setup PostgreSQL Server' do
      # port node['mediawiki']['wgDBport'].to_i
      version node['mediawiki']['postgreql_version']
      # password node['mediawiki']['wgDBpassword']
      action [:install, :init_server]
    end

    # postgresql_database node['mediawiki']['wgDBname'] do
    #   port node['mediawiki']['wgDBport'].to_i
    #   owner 'postgres'
    # end

    # postgresql_user node['mediawiki']['wgDBuser'] do
    #   port node['mediawiki']['wgDBport'].to_i
    #   database node['mediawiki']['wgDBname']
    #   password node['mediawiki']['wgDBpassword']
    #   superuser true
    #   createdb true
    #   createrole true
    # end
  end
end

# Generate a self-signed if we don't have a cert to prevent bootstrap problems
acme_selfsigned "#{node['mediawiki']['servername']}" do
  crt     "#{node['mediawiki']['certificate_directory']}/#{node['mediawiki']['certificates'][0]}.cert"
  key     "#{node['mediawiki']['private_key_directory']}/#{node['mediawiki']['certificates'][0]}.key"
  chain    "#{node['mediawiki']['certificate_directory']}/chain.pem"
  owner   'root'
  group   'root'
  notifies :restart, "apache2_service[httpd]", :delayed
end

apache2_default_site 'wiki' do
  default_site_name 'wiki'
  docroot_dir node['mediawiki']['mediawiki_dir']
  port '443'
  template_source 'wiki.conf.erb'
  action :enable
  notifies :reload, 'apache2_service[httpd]'
end

# web_app 'wiki' do
#   docroot node['mediawiki']['web_dir']
#   servername node['mediawiki']['servername']
#   serveraliases [node[:hostname], 'wiki']
#   certname "#{node['mediawiki']['certificates'][0]}"
#   mediawiki_dir node['mediawiki']['mediawiki_dir']
#   template 'wiki.conf.erb'
# end

execute "Setup MediaWiki" do
  command "php #{node['mediawiki']['install_dir']}/maintenance/install.php --dbtype #{node['mediawiki']['wgDBtype']} --dbname #{node['mediawiki']['wgDBname']} --dbuser #{node['mediawiki']['wgDBuser']} --dbpass #{node['mediawiki']['wgDBpassword']} --pass #{node['mediawiki']['admin_user_password']} #{node['mediawiki']['wgSitename']} #{node['mediawiki']['admin_user']}"
  not_if {File.exists?("#{node['mediawiki']['install_dir']}/LocalSettings.php")}
end

if !node['mediawiki']['wgLogo_remote'].nil?
  logo = node['mediawiki']['wgLogo_remote'].split('/')[-1]
  remote_file "#{node['mediawiki']['install_dir']}/images/#{logo}" do
    source node['mediawiki']['wgLogo_remote']
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    mode '0744'
    action :create
  end
end

template "#{node['mediawiki']['install_dir']}/LocalSettings.php" do
  source 'LocalSettings.php.erb'
  mode 0600
  owner node['mediawiki']['owner']
  group node['mediawiki']['group']
end

if node['mediawiki']['ldap'] == true
  if platform_family?('rhel')
    packages = %w(php-ldap)
  elsif platform_family?('debian')
    packages = %w(php5-ldap)
  end
  packages.each do |pkg|
    package pkg do
      action :install
    end
  end

  remote_file '/var/chef/files/LDAPAuthentication.tar.gz' do
    source node['mediawiki']['ldapplugin_url']
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end
  
  archive_file '/var/chef/files/LDAPAuthentication.tar.gz' do
    destination "#{node['mediawiki']['install_dir']}/extensions/"
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    strip_components 1
    overwrite false
    action :extract
  end

  # tar_extract node['mediawiki']['ldapplugin_url'] do
  #   target_dir "#{node['mediawiki']['install_dir']}/extensions"
  #   creates "#{node['mediawiki']['install_dir']}/extensions/LdapAuthentication"
  # end
  execute 'Setup LDAP Database' do
    command "php #{node['mediawiki']['install_dir']}/maintenance/update.php"
  end
end

execute 'Changing Permissions on MediaWiki install' do
  command "chown -R  #{node['mediawiki']['owner']}:#{node['mediawiki']['group']} #{node['mediawiki']['install_dir']}"
end

# link '/etc/httpd/mods-enabled/php5.load' do
#   action :delete
# end

# link '/etc/httpd/mods-enabled/php7.load' do
#   to '/etc/httpd/mods-available/php7.load'
#   action :create
# end

# link '/etc/httpd/mods-enabled/php.conf' do
#   to '/etc/httpd/mods-available/php.conf'
#   action :create
# end

# service 'httpd' do
#   if platform_family?('rhel')
#     service_name 'httpd'
#   elsif platform_family?('debian')
#     service_name 'apache2'
#   end
#   action [:enable, :start]
# end

if node['kitchen'].nil?
  # Get and auto-renew the certificate from Let's Encrypt
  acme_certificate "#{node['mediawiki']['servername']}" do
    crt     "#{node['mediawiki']['certificate_directory']}/#{node['mediawiki']['certificates'][0]}.cert"
    key     "#{node['mediawiki']['private_key_directory']}/#{node['mediawiki']['certificates'][0]}.key"
    wwwroot  node['mediawiki']['web_dir']
    notifies :restart, "apache2_service[httpd]", :delayed
  end
end

apache2_service 'httpd' do
  action [:enable, :start]
end

# Remove secret attributes
ruby_block 'remove-secret-attributes' do
  block do
    node.rm('mediawiki', 'wgDBuser')
    node.rm('mediawiki', 'wgDBpassword')
    node.rm('mediawiki', 'admin_user')
    node.rm('mediawiki', 'admin_user_password')
    node.rm('mediawiki', 'wgSecretKey')
    node.rm('mediawiki', 'wgLDAPProxyAgent')
    node.rm('mediawiki', 'wgLDAPProxyAgentPassword')
  end
  subscribes :create, 'template[#{node[:mediawiki][:install_dir]}/LocalSettings.php]', :immediately
end
