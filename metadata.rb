name             'mediawiki'
maintainer       'UAF-GINA'
maintainer_email 'support+chef@gina.alaska.edu'
license          'Apache 2.0'
description      'Installs/Configures mediawiki'
long_description 'Installs/Configures mediawiki'
version          '1.0.0'

supports 'rhel', '=6'

depends 'apache2', '=3.1.0'
depends 'certificate', '=1.0.0'
depends 'chef-vault', '=1.3.0'
depends 'database', '=4.0.9'
depends 'php', '=1.7.2'
depends 'postgresql', '3.4.20'
depends 'tar', '=0.7.0'
depends 'chef-sugar'
