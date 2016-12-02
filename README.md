# mediawiki-cookbook

Installs MediaWiki software from https://www.mediawiki.org.

## Supported Platforms

RHEL 6

## Usage

### mediawiki::default

Include `mediawiki` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[mediawiki::default]"
  ]
}
```

Setup a wiki secrets vault item
```
{
  "id": "wiki",
  "wgDBuser": "wiki_user",
  "wgDBpassword": "blah",
  "admin_user": "admin",
  "admin_password": "blah",
  "wgSecretKey": "456f5233c29d99bba572957ff3984e773b4633ba802466572793ea4889ed14c5",
  "wgLDAPProxyAgent": { "blah_example_com":"uid=blahuser,ou=resource,dc=blah,dc=com" },
  "wgLDAPProxyAgentPassword": { "blah_example_com":"blah" }
}
```

Setup an SSL vault item with your certificate and key


## Attributes

## default.rb

Base directory to install mediawiki into

```ruby
default['mediawiki']['web_dir'] = '/var/www/html'
```

Sub directory to install mediawiki into

```ruby
default['mediawiki']['mediawiki_dir'] = 'mediawiki'
```

Owner and group for mediawiki directories and files

```ruby
default['mediawiki']['owner'] = 'apache'
default['mediawiki']['group'] = 'apache'
```

FQDN of wiki host

```ruby
default['mediawiki']['servername'] = 'localhost'
```

Port number to host SSL site on

```ruby
default['mediawiki']['port'] = '5443'
```

Vault and vault item name to hold database user/pass, admin user/pass, secret key and LDAP stuff

```ruby
default['mediawiki']['vault'] = 'web_app_secrets'
default['mediawiki']['vault_item'] = 'wiki'
```

Main and patch versions

```ruby
default['mediawiki']['main_version'] = '1.25'
default['mediawiki']['patch_version'] = '.3'
```

Checksum for mediawiki tar.gz file

```ruby
default['mediawiki']['mediawiki-checksum'] = '53f3dc6fc7108c835fbfefb09d76e84067112538aaed433d89d7d4551dc205ba'
```

Wiki name

```ruby
default['mediawiki']['wgSitename'] = 'Sitename'
```

URL to artwork for logo. Gets copied onto wiki server. Needs to be 135 x 135 pixels.

```ruby
default['mediawiki']['wgLogo_remote'] = nil
```

Allowed uploaded file types

```ruby
default['mediawiki']['wgFileExtensions'] = [ 'png', 'gif', 'jpg', 'jpeg' ]
```

Database setup

```ruby
default['mediawiki']['local_database'] = true
default['mediawiki']['wgDBtype'] = 'postgres'
default['mediawiki']['wgDBname'] = 'wiki'
default['mediawiki']['wgDBport'] = '5432'
default['mediawiki']['wgDBserver'] = '127.0.0.1'
```

Block logins if user is disabled

```ruby
default['mediawiki']['wgBlockDisablesLogin'] = false
```

LDAP setup. If you don't want it just set first setting to false.

```ruby
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
```

When LDAP is disabled you might want to allow users to sign up for accounts
```ruby
default['mediawiki']['wgAllowUserSignup'] = true
```

SSL Cert

```ruby
override['ssl-vault']['certificates'] = ['wiki']
if platform_family?('rhel')
  override['ssl-vault']['private_key_directory'] = '/etc/pki/tls/private'
  override['ssl-vault']['certificate_directory'] = '/etc/pki/tls/certs'
end
```

PHP Settings - Currently only setting upload size stuff but could be used to set other special PHP settings

```ruby
override['php']['directives'] = { upload_max_filesize: "20M", post_max_size: "20M" }
```

Database Configuration

```ruby
override['postgresql']['enable_pgdg_yum'] = true
override['postgresql']['version'] = '9.3'
override['postgresql']['dir'] = "/var/lib/pgsql/#{node['postgresql']['version']}/data"
override['postgresql']['config']['data_directory'] = "/var/lib/pgsql/#{node['postgresql']['version']}/data"
override['postgresql']['client']['packages'] = %w(postgresql93 postgresql93-devel)
override['postgresql']['server']['packages'] = %w(postgresql93-server)
override['postgresql']['server']['service_name'] = "postgresql-#{node['postgresql']['version']}"
override['postgresql']['contrib']['packages'] = %w(postgresql93-contrib)
override['postgresql']['config']['listen_addresses'] = '0.0.0.0'
override['postgresql']['config']['port'] = node['mediawiki']['wgDBport']
```

## TODO

* Wiki extensions attribute array
* Don't always force https
* Change and setup upload dir
* Fill out documentation
* SELinux Support
* MySQL Support
* Setup wgEmergencyContact and wgPasswordSender
* Tests
* Ubuntu Support
* RHEL 7 Support

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-new-recipe`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Author:: Jeremiah Dabney (<jsdabney@alaska.edu>)
