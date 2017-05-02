name             'mediawiki'
maintainer       'UAF-RCS'
maintainer_email 'chef@rcs.alaska.edu'
license          'Apache 2.0'
description      'Installs/Configures mediawiki'
long_description 'Installs/Configures mediawiki'
version          '2.1.1'

chef_version '>= 12.14' if respond_to?(:chef_version)

supports 'rhel', '=6'

depends 'apache2', '~> 3.3.0'
depends 'ssl-vault', '~> 1.1.15'
depends 'chef-vault', '~> 2.1.1'
depends 'database', '~> 6.1.1'
depends 'php', '~> 4.0.0'
depends 'postgresql', '~> 6.1.1'
depends 'tar', '~> 2.0.0'
depends 'chef-sugar'
