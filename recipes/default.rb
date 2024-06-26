
# Cookbook Name:: mediawiki
# Recipe:: default

# Copyright (C) 2015 UAF-RCS

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#    http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# include_recipe 'chef-vault::default'
# include_recipe 'php::ini'
# include_recipe 'acme::default'

# if platform_family?('rhel')
#   if node['platform_version'].to_f <= 8.0
#     package 'epel-release' do
#       action :install
#     end
#     remote_file "#{Chef::Config[:file_cache_path]}/remi-release-8.rpm" do
#       source 'http://rpms.remirepo.net/enterprise/remi-release-8.rpm'
#       owner 'root'
#       group 'root'
#       mode '0744'
#       action :create
#     end
#     dnf_package 'remi-release-8.rpm' do
#       source "#{Chef::Config[:file_cache_path]}/remi-release-8.rpm"
#       action :install
#     end
#     bash 'Install php' do
#       code <<-EOH
#         dnf -y install dnf-plugins-core
#         dnf module -y reset php
#         dnf module -y install php:remi-7.3
#       EOH
#     end
#     packages = %w(php73-php-xml php73-php php73-php-pecl-apcu php-intl git ImageMagick)
#   elsif node['platform_version'].to_f >= 9.0
#     package 'epel-release' do
#       action :install
#     end
#     remote_file "#{Chef::Config[:file_cache_path]}/remi-release-9.rpm" do
#       source 'http://rpms.remirepo.net/enterprise/remi-release-9.rpm'
#       owner 'root'
#       group 'root'
#       mode '0744'
#       action :create
#     end
#     dnf_package 'remi-release-9.rpm' do
#       source "#{Chef::Config[:file_cache_path]}/remi-release-9.rpm"
#       action :install
#     end
#     bash 'Install php' do
#       code <<-EOH
#         dnf -y install dnf-plugins-core
#         dnf module -y reset php
#         dnf module -y install php:remi-8.1
#       EOH
#     end
#     # packages = %w(php82-php-xml php82-php php82-php-pecl-apcu php82-php-intl php82-php-pgsql git ImageMagick)
#     packages = %w(ImageMagick git php81-php php81-php-gd php81-php-intl php81-php-json php81-php-mbstring php81-php-pecl-apcu php81-php-pgsql php81-php-xml)
#   end
# elsif platform_family?('debian')
#   packages = %w(php-xml-parser php-apc php5-intl git ImageMagick)
# else
#   packages = %w( )
# end

package 'epel-release' do
  action :install
end

packages = %w(ImageMagick git php-cli php-gd php-intl php-json php-mbstring php-pecl-apcu php-pgsql php-xml php-fpm)

packages.each do |pkg|
  package pkg do
    action :install
  end
end

# if platform_family?('rhel')
#   if node['platform_version'].to_f >= 9.0
#     link '/usr/bin/php' do
#       to '/usr/bin/php82'
#       action :create
#     end
#   end
# end

# cookbook_file '/etc/httpd/mods-available/php.load' do
#   source 'php.load'
#   action :create
# end

# Grab settings from vault
node.default['mediawiki']['wgDBuser'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgDBuser']
node.default['mediawiki']['wgDBpassword'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgDBpassword']
node.default['mediawiki']['admin_user'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['admin_user']
node.default['mediawiki']['admin_user_password'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['admin_password']
node.default['mediawiki']['wgSecretKey'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgSecretKey']
node.default['mediawiki']['wgLDAPProxyAgent'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgLDAPProxyAgent']
node.default['mediawiki']['wgLDAPProxyAgentPassword'] = ChefVault::Item.load("#{node['mediawiki']['vault']}", "#{node['mediawiki']['vault_item']}")['wgLDAPProxyAgentPassword']

apache2_install 'default_install' do
  notifies :restart, 'apache2_service[httpd]'
end

# apache2_module 'php' do
#   notifies :reload, 'apache2_service[httpd]'
# end

apache2_module 'ssl' do
  notifies :reload, 'apache2_service[httpd]'
end

link '/etc/httpd/mods-enabled/rewrite.load' do
  to '/etc/httpd/mods-available/rewrite.load'
  action :create
end

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
      version node['mediawiki']['postgreql_version']
      action [:install, :init_server]
    end

    postgresql_config 'postgresql-server' do
      version '15'
      server_config({
        'max_connections' => 110,
        'shared_buffers' => '128MB',
        'dynamic_shared_memory_type' => 'posix',
        'max_wal_size' => '1GB',
        'min_wal_size' => '80MB',
        'log_destination' => 'stderr',
        'logging_collector' => true,
        'log_directory' => 'log',
        'log_filename' => 'postgresql-%a.log',
        'log_rotation_age' => '1d',
        'log_rotation_size' => 0,
        'log_truncate_on_rotation' => true,
        'log_line_prefix' => '%m [%p]',
        'log_timezone' => 'Etc/UTC',
        'datestyle' => 'iso, mdy',
        'timezone' => 'Etc/UTC',
        'lc_messages' => 'C',
        'lc_monetary' => 'C',
        'lc_numeric' => 'C',
        'lc_time' => 'C',
        'default_text_search_config' => 'pg_catalog.english',
      })
      notifies :restart, 'postgresql_service[postgresql]', :delayed
      action :create
    end

    postgresql_service 'postgresql' do
      action %i(enable start)
    end

    postgresql_access 'local all all peer delete' do
      type 'local'
      database 'all'
      user 'all'
      auth_method 'peer'
      action :delete
    end

    postgresql_access 'postgresql host superuser' do
      type 'host'
      database 'all'
      user 'postgres'
      address '127.0.0.1/32'
      auth_method 'md5'
      notifies :reload, 'postgresql_service[postgresql]', :delayed
    end

    postgresql_database node['mediawiki']['wgDBname'] do
      port node['mediawiki']['wgDBport'].to_i
      owner 'postgres'
    end

    postgresql_role node['mediawiki']['wgDBuser'] do
      unencrypted_password node['mediawiki']['wgDBpassword']
      superuser true
      createdb true
      createrole true
      login true
    end
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

# link '/usr/lib64/httpd/modules/mod_php.so' do
#   to '/opt/remi/php82/root/usr/lib64/httpd/modules/libphp.so'
#   action :create
# end

apache2_default_site 'wiki' do
  default_site_name 'wiki'
  docroot_dir node['mediawiki']['mediawiki_dir']
  port '443'
  template_source 'wiki.conf.erb'
  template_cookbook 'mediawiki'
  variables(
    server_name: node['mediawiki']['servername'],
    document_root: node['mediawiki']['web_dir'],
    server_aliases: [node[:hostname], 'wiki'],
    certname: "#{node['mediawiki']['certificates'][0]}",
    mediawiki_dir: node['mediawiki']['mediawiki_dir'],
    log_dir: lazy { default_log_dir },
    site_name: 'basic_site'
  )
  action :enable
  notifies :reload, 'apache2_service[httpd]'
end

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
  
  archive_file 'LDAPAuthentication.tar.gz' do
    path '/var/chef/files/LDAPAuthentication.tar.gz'
    destination "#{node['mediawiki']['install_dir']}/extensions"
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    strip_components 0
    overwrite true
    action :extract
  end

  remote_file '/var/chef/files/LDAPProvider.tar.gz' do
    source node['mediawiki']['ldapprovider_url']
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end
  
  archive_file 'LDAPProvider.tar.gz' do
    path '/var/chef/files/LDAPProvider.tar.gz'
    destination "#{node['mediawiki']['install_dir']}/extensions"
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    strip_components 0
    overwrite true
    action :extract
  end

  remote_file '/var/chef/files/LDAPProvider.tar.gz' do
    source node['mediawiki']['ldapprovider_url']
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end
  
  archive_file 'LDAPProvider.tar.gz' do
    path '/var/chef/files/LDAPProvider.tar.gz'
    destination "#{node['mediawiki']['install_dir']}/extensions"
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    strip_components 0
    overwrite true
    action :extract
  end

  remote_file '/var/chef/files/PluggableAuth.tar.gz' do
    source node['mediawiki']['pluggableauth_url']
    owner 'root'
    group 'root'
    mode '0700'
    action :create
  end
  
  archive_file 'PluggableAuth.tar.gz' do
    path '/var/chef/files/PluggableAuth.tar.gz'
    destination "#{node['mediawiki']['install_dir']}/extensions"
    owner node['mediawiki']['owner']
    group node['mediawiki']['group']
    strip_components 0
    overwrite true
    action :extract
  end

  execute 'Setup LDAP Database' do
    command "php #{node['mediawiki']['install_dir']}/maintenance/update.php"
  end
end

execute 'Changing Permissions on MediaWiki install' do
  command "chown -R  #{node['mediawiki']['owner']}:#{node['mediawiki']['group']} #{node['mediawiki']['install_dir']}"
end

# if ENV['TEST_KITCHEN'].nil?
#   # Get and auto-renew the certificate from Let's Encrypt
#   acme_certificate "#{node['mediawiki']['servername']}" do
#     crt     "#{node['mediawiki']['certificate_directory']}/#{node['mediawiki']['certificates'][0]}.cert"
#     key     "#{node['mediawiki']['private_key_directory']}/#{node['mediawiki']['certificates'][0]}.key"
#     wwwroot  node['mediawiki']['web_dir']
#     notifies :restart, "apache2_service[httpd]", :delayed
#   end
# end

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
