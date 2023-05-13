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

# Non-user permissions
default['mediawiki']['allow_everyone_edit'] = 'false'
default['mediawiki']['allow_everyone_read'] = 'true'
default['mediawiki']['allow_create_account'] = 'true'

# FQDN of wiki host
default['mediawiki']['servername'] = 'localhost'

# Port number to host SSL site on
default['mediawiki']['port'] = '5443'

default['mediawiki']['wgServer'] = "https://#{node['mediawiki']['servername']}:#{node['mediawiki']['port']}"

# Vault and vault item name to hold database user/pass, admin user/pass, secret key and LDAP stuff
default['mediawiki']['vault'] = 'web_app_secrets'
default['mediawiki']['vault_item'] = 'wiki'

# Main and patch versions
default['mediawiki']['main_version'] = '1.38'
default['mediawiki']['patch_version'] = '.1'

# Checksum for mediawiki tar.gz file
default['mediawiki']['mediawiki-checksum'] = '117365525a0def1b209ca50857d65736b62545b877a75348a57a85d126437b31'

default['mediawiki']['full_version'] = "#{node['mediawiki']['main_version']}#{node['mediawiki']['patch_version']}"

default['mediawiki']['package_url'] = "http://releases.wikimedia.org/mediawiki/#{node['mediawiki']['main_version']}/mediawiki-#{node['mediawiki']['full_version']}.tar.gz"

# Wiki name
default['mediawiki']['wgSitename'] = 'Sitename'

# URL to artwork for logo. Gets copied onto wiki server. Needs to be 135 x 135 pixels.
default['mediawiki']['wgLogo_remote'] = nil

# Allowed uploaded file types
default['mediawiki']['wgFileExtensions'] = ['png', 'gif', 'jpg', 'jpeg']

# Database setup
default['mediawiki']['local_database'] = true
default['mediawiki']['wgDBtype'] = 'postgres'
default['mediawiki']['wgDBname'] = 'wiki'
default['mediawiki']['wgDBport'] = '5432'
default['mediawiki']['wgDBserver'] = '127.0.0.1'

# Block logins if user is disabled
default['mediawiki']['wgBlockDisablesLogin'] = false

# LDAP setup. If you don't want it just set first setting to false.
# default['mediawiki']['ldap'] = true
default['mediawiki']['ldap'] = false
default['mediawiki']['ldapplugin_url'] = 'https://extdist.wmflabs.org/dist/extensions/LDAPAuthentication2-REL1_38-502759b.tar.gz'
#default['mediawiki']['wgLDAPDomainNames'] = ['blah_example_com']
#default['mediawiki']['wgLDAPServerNames'] = { blah_example_com: 'blah.example.com' }
#default['mediawiki']['wgLDAPEncryptionType'] = { blah_example_com: 'ssl' }
#default['mediawiki']['wgLDAPSearchAttributes'] = { blah_example_com: 'systemid' }
#default['mediawiki']['wgLDAPBaseDNs'] = { blah_example_com: 'ou=peopledc=example,dc=com' }
default['mediawiki']['wgLDAPUseLocal'] = false
#default['mediawiki']['wgLDAPPreferences'] = { blah_example_com: "array( 'email' => 'mail')" }
#default['mediawiki']['wgLDAPDisableAutoCreate'] = { blah_example_com: false }

normal['mediawiki']['certificates'] = ['wiki']
normal['mediawiki']['private_key_directory'] = '/etc/pki/tls/private'
normal['mediawiki']['certificate_directory'] = '/etc/pki/tls/certs'

# PHP Settings - Currently only setting upload size stuff but could be used to set other special PHP settings
normal['php']['directives'] = { upload_max_filesize: '20M', post_max_size: '20M' }

# Database version
default['mediawiki']['postgreql_version'] = '15'