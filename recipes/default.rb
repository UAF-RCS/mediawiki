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

include_recipe 'postgresql::ruby'
include_recipe 'postgresql::server'
include_recipe 'database::postgresql'
include_recipe 'tar::default'
include_recipe 'chef-vault::default'
include_recipe 'apache2::default'
include_recipe 'apache2::mod_ssl'
include_recipe 'apache2::mod_php'
include_recipe 'php::ini'
include_recipe 'ssl-vault::default'

if platform_family?('rhel')
  packages = %w(php-xml php-pecl-apc php-intl git ImageMagick)
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

directory node['mediawiki']['install_dir'] do
  action :create
  recursive true
end

tar_extract node['mediawiki']['package_url'] do
  target_dir node['mediawiki']['install_dir']
  creates "#{node['mediawiki']['install_dir']}/extensions"
  checksum '53f3dc6fc7108c835fbfefb09d76e84067112538aaed433d89d7d4551dc205ba'
  tar_flags ['--strip 1']
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

    postgresql_connection_info = { host: '127.0.0.1',
                                   port: node['mediawiki']['wgDBport'],
                                   username: 'postgres',
                                   password: node['postgresql']['password']['postgres'] }

    postgresql_database node['mediawiki']['wgDBname'] do
      connection postgresql_connection_info
      action :create
    end

    postgresql_database_user node['mediawiki']['wgDBuser'] do
      connection postgresql_connection_info
      password node['mediawiki']['wgDBpassword']
      action :create
    end

    postgresql_database_user node['mediawiki']['wgDBuser'] do
      connection postgresql_connection_info
      database_name node['mediawiki']['wgDBname']
      privileges [:all]
      action :grant
    end
  end
end

web_app 'wiki' do
  docroot node['mediawiki']['web_dir']
  servername node['mediawiki']['servername']
  serveraliases [node[:hostname], 'wiki']
  certname node['ssl-vault']['certificates'][0]
  mediawiki_dir node['mediawiki']['mediawiki_dir']
  template 'wiki.conf.erb'
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
  tar_extract node['mediawiki']['ldapplugin_url'] do
    target_dir "#{node['mediawiki']['install_dir']}/extensions"
    creates "#{node['mediawiki']['install_dir']}/extensions/LdapAuthentication"
  end
  execute 'Setup LDAP Database' do
    command "php #{node['mediawiki']['install_dir']}/maintenance/update.php"
  end
end

execute 'Changing Permissions on MediaWiki install' do
  command "chown -R  #{node['mediawiki']['owner']}:#{node['mediawiki']['group']} #{node['mediawiki']['install_dir']}"
end

service 'httpd' do
  if platform_family?('rhel')
    service_name 'httpd'
  elsif platform_family?('debian')
    service_name 'apache2'
  end
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
