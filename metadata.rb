name             'mediawiki'
maintainer       'UAF-RCS'
maintainer_email 'chef@rcs.alaska.edu'
license          'Apache 2.0'
description      'Installs/Configures mediawiki'
long_description 'Installs/Configures mediawiki'
version          '3.0.18'

chef_version '> 17.0'

# supports 'rhel', '= 8'

depends 'apache2', '~> 9.0.0'
depends 'acme'
depends 'chef-vault'
depends 'php', '~> 9.2.0'
depends 'postgresql', '~> 11.2.0'
