# == Class: puppet_master::puppetdb
#
# Module to manage the certificate whitelist for PuppetDB.
# Collects all instances of puppet_master::puppetdb::whitelist_entry
#
# === Parameters
#
# Defaults in puppet_master::params
#
# [*all_in_one*]
#   Boolean value to determine if the node is an all-in-one installations
#   Default is true.
#
# [*default_whitelist*]
#   An array of the default entries in the whitelist.
#   Defaults to [$::fqdn, 'pe-internal-dashboard'].
#
# === Examples
#
#  class { 'puppet_master::puppetdb':
#     default_whitelist => [$::fqdn, 'pe-internal-dashboard'],
#     all_in_one        => true,
#  }
#
# === Authors
#
# Brett Gray <brett.gray@puppetlabs.vm>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class puppet_master::puppetdb (
  $all_in_one        = $puppet_master::params::all_in_one,
  $default_whitelist = $puppet_master::params::default_whitelist,
) inherits puppet_master::params {

  file { '/etc/puppetlabs/puppetdb/certificate-whitelist':
    ensure => file,
    owner  => 'pe-puppetdb',
    group  => 'pe-puppetdb',
    mode   => '0600',
  }

  if $all_in_one == false {
    puppet_master::puppetdb::whitelist_entry { $default_whitelist: }
  }

  Puppet_master::Puppetdb::Whitelist_entry <<| |>>
}
