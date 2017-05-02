name 'build_cookbook'
maintainer 'UAF RCS'
maintainer_email 'chef@rcs.alaska.edu'
license 'mit'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'delivery-truck'
