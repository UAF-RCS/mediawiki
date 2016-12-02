# Base directory to install mediawiki into
default['mediawiki']['web_dir'] = '/var/www/html'
# Sub directory to install mediawiki into
default['mediawiki']['mediawiki_dir'] = 'mediawiki'

default['mediawiki']['install_dir'] = "#{node['mediawiki']['web_dir']}/#{node['mediawiki']['mediawiki_dir']}"

# Owner and group for mediawiki directories and files
if platform_family?('rhel')
  default['mediawiki']['owner'] = 'apache'
  default['mediawiki']['group'] = 'apache'
elsif platform_family?('debian')
  default['mediawiki']['owner'] = 'root'
  default['mediawiki']['group'] = 'www-data'
end

# FQDN of wiki host
default['mediawiki']['servername'] = 'localhost'

# Port number to host SSL site on
default['mediawiki']['port'] = '5443'

default['mediawiki']['wgServer'] = "https://#{node['mediawiki']['servername']}:#{node['mediawiki']['port']}"

# Vault and vault item name to hold database user/pass, admin user/pass, secret key and LDAP stuff
default['mediawiki']['vault'] = 'web_app_secrets'
default['mediawiki']['vault_item'] = 'wiki'

# Main and patch versions
default['mediawiki']['main_version'] = '1.25'
default['mediawiki']['patch_version'] = '.3'

default['mediawiki']['full_version'] = "#{node['mediawiki']['main_version']}#{node['mediawiki']['patch_version']}"

default['mediawiki']['package_url'] = "http://releases.wikimedia.org/mediawiki/#{node['mediawiki']['main_version']}/mediawiki-#{node['mediawiki']['full_version']}.tar.gz"

# Checksum for mediawiki tar.gz file
default['mediawiki']['mediawiki-checksum'] = '53f3dc6fc7108c835fbfefb09d76e84067112538aaed433d89d7d4551dc205ba'

# Wiki name
default['mediawiki']['wgSitename'] = 'Sitename'

# Disable allowing users to create accounts
default['mediawiki']['wgAllowUserSignup'] = false

# URL to artwork for logo. Gets copied onto wiki server. Needs to be 135 x 135 pixels.
default['mediawiki']['wgLogo_remote'] = nil

# Allowed uploaded file types
default['mediawiki']['wgFileExtensions'] = [ 'png', 'gif', 'jpg', 'jpeg' ]

# Database setup
default['mediawiki']['local_database'] = true
default['mediawiki']['wgDBtype'] = 'postgres'
default['mediawiki']['wgDBname'] = 'wiki'
default['mediawiki']['wgDBport'] = '5432'
default['mediawiki']['wgDBserver'] = '127.0.0.1'

# Block logins if user is disabled
default['mediawiki']['wgBlockDisablesLogin'] = false

# LDAP setup. If you don't want it just set first setting to false.
default['mediawiki']['ldap'] = true
default['mediawiki']['ldapplugin_url'] = 'https://extdist.wmflabs.org/dist/extensions/LdapAuthentication-REL1_25-d4db6f0.tar.gz'
default['mediawiki']['wgLDAPDomainNames'] = [ 'blah_example_com' ]
default['mediawiki']['wgLDAPServerNames'] = { blah_example_com: 'blah.example.com' }
default['mediawiki']['wgLDAPEncryptionType'] = { blah_example_com: 'ssl' }
default['mediawiki']['wgLDAPSearchAttributes'] = { blah_example_com: 'systemid' }
default['mediawiki']['wgLDAPBaseDNs'] = { blah_example_com: 'ou=peopledc=example,dc=com' }
default['mediawiki']['wgLDAPUseLocal'] = false
default['mediawiki']['wgLDAPPreferences'] = { blah_example_com: "array( 'email' => 'mail')" }
default['mediawiki']['wgLDAPDisableAutoCreate'] = { blah_example_com: false }

# SSL Cert
normal['ssl-vault']['certificates'] = ['wiki']
if platform_family?('rhel')
  normal['ssl-vault']['private_key_directory'] = '/etc/pki/tls/private'
  normal['ssl-vault']['certificate_directory'] = '/etc/pki/tls/certs'
end

# PHP Settings - Currently only setting upload size stuff but could be used to set other special PHP settings
normal['php']['directives'] = { upload_max_filesize: "20M", post_max_size: "20M" }

# Database version
normal['postgresql']['version'] = '9.3'

# Database Configuration
normal['postgresql']['config']['listen_addresses'] = '0.0.0.0'
normal['postgresql']['config']['port'] = node['mediawiki']['wgDBport']
override['postgresql']['config']['ssl'] = false

if platform_family?('rhel')
  normal['postgresql']['enable_pgdg_yum'] = true
  normal['postgresql']['client']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}", "postgresql#{node['postgresql']['version'].split('.').join}-devel"]
  normal['postgresql']['server']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}-server"]
  normal['postgresql']['contrib']['packages'] = ["postgresql#{node['postgresql']['version'].split('.').join}-contrib"]
  normal['postgresql']['dir'] = "/var/lib/pgsql/#{node['postgresql']['version']}/data"
  normal['postgresql']['config']['data_directory'] = "/var/lib/pgsql/#{node['postgresql']['version']}/data"
  normal['postgresql']['server']['service_name'] = "postgresql-#{node['postgresql']['version']}"
elsif platform_family?('debian')
  normal['postgresql']['enable_pgdg_apt'] = true
  normal['postgresql']['client']['packages'] = ["postgresql-client-#{node['postgresql']['version']}", "postgresql-server-dev-#{node['postgresql']['version']}"]
  normal['postgresql']['server']['packages'] = ["postgresql-#{node['postgresql']['version']}"]
  normal['postgresql']['contrib']['packages'] = ["postgresql-contrib-#{node['postgresql']['version']}"]
  normal['postgresql']['dir'] = "/var/lib/postgresql/#{node['postgresql']['version']}/main"
  normal['postgresql']['config']['data_directory'] = "/var/lib/postgresql/#{node['postgresql']['version']}/main"
  normal['postgresql']['server']['service_name'] = 'postgresql'
end
