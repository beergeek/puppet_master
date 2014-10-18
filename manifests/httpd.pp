# == Class: puppet_master::httpd
#
# Module to manage the puppetmaster configuration and pe-httpd service.
#
# === Parameters
#
# Defaults in puppet_master::params
#
# [*dns_alt_names*]
#   Array of DNS Alt Names used for the server alias within the puppetmaster.conf fir pe-httpd
#   Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]
#   Required.
#
# [*ca_enabled*]
#   Boolean value to determine if node is CA server.
#   Default is false.
#
# [*ca_server*]
#   Hostname of the CA server (string).
#   Defaults to $::settings::server
#
# [*manage_master*]
# Boolean value determining if the puppetmaster.conf file will be managed.
# Default is true.
#
# [*manage_console*]
# Boolean value determining if the puppetdashboard.conf file we be managed.
# Value does not currently function.
#
# === Examples
#
#  class { 'puppet_master::httpd':
#     ca_enabled    => false,
#     server        => 'cbr1puppetlabspmom1.puppetlabs.local',
#     manage_master => true,
#     dns_alt_names => ['com1','com1.puppetlabs.local','puppet','puppet.puppetlabs.local'],
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
class puppet_master::httpd (
  $ca_enabled     = $puppet_master::params::ca_enabled,
  $ca_server      = $puppet_master::params::ca_server,
  $dns_alt_names  = $puppet_master::params::dns_alt_names,
  $manage_console = $puppet_master::params::manage_console,
  $manage_master  = $puppet_master::params::manage_master,
) inherits puppet_master::params {

  #validation
  validate_bool($ca_enabled)
  validate_bool($manage_console)
  validate_bool($manage_master)
  validate_array($dns_alt_names)

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { ['/etc/puppetlabs/httpd','/etc/puppetlabs/httpd/conf.d']:
    ensure => directory,
  }

  if $manage_master {
    file { '/etc/puppetlabs/httpd/conf.d/puppetmaster.conf':
      ensure  => file,
      content => template('puppet_master/puppetmaster.conf'),
      notify  => Service['pe-httpd'],
    }
  }

  service { 'pe-httpd':
    ensure => running,
    enable => true,
  }

}
