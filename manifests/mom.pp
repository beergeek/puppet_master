# == Class: puppet_master::mom
#
# Class to manage the Puppet Master of Masters node.
#
# === Parameters
#
# [*ca_enabled*]
#   Boolean value to determine if the node has the CA service enabled.
#   Default is false,
#
# [*ca_server*]
#   Host name (string) of the CA if the current node is not.
#   Default to undef
#   Required if ca_enabled is false.
#
# [*dns_alt_names*]
#   Array of DNS Alt Names used for the server alias within the puppetmaster.conf fir pe-httpd
#   Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]
#   Required.
#
# [*hiera_base*]
#   Hiera data directory on node.
#   Default is "${::settings::confdir}/hieradata".
#
# [*hiera_file*]
#   Location of source for Hiera config file.
#   Defaults to 'puppet:///modules/puppet_master/hiera.yaml'.
#
# [*hiera_remote*]
#   URL of the remote GIT repo for Hiera.
#   Required if ca_enabled is false.
#
# [*puppet_base*]
#   Directory for the Puppet environments.
#   Targeted towards directory environments.
#   Default is "${::settings::confdir}/environments".
#
# [*puppet_remote*]
#   URL of remote GIT repo for Puppetfile.
#   Default is undef.
#
# [*purge_hosts*]
#   Boolean value to determine if hosts file is purged of non-Puppet managed entries.
#   Default is false.
#
# [*r10k_enabled*]
#   Boolean value to determine if r10k is managed by Puppet.
#   Default is true.
#
# [*vip*]
#   VIP name that will be used in the site.pp for the filebucket location.
#   Defaults to puppet.${::domain}
#   Required.
#
# === Examples
#
#  class { puppet_master:
#     master        => 'mom0.puppetlabs.local',
#     ca_enabled    => false,
#     ca_server     => 'mom0.puppetlabs.local',
#     server        => 'mom0.puppetlabs.local',
#     vip           => 'puppet.uberu.local',
#     dns_alt_names => ['cbr1uberupcom1','cbr1uberupcom1.uberu.local','puppet','puppet.uberu.local'],
#  }
#
# === Authors
#
# Brett Gray <brett.gray@puppetlabs.vm>
#
# === Copyright
#
# Copyright 2014 Brett Gray.
#
class puppet_master::mom (
  $dns_alt_names = $puppet_master::params::dns_alt_names,
  $hiera_base    = $puppet_master::params::hiera_base,
  $hiera_file    = $puppet_master::params::hiera_file,
  $hiera_remote  = $puppet_master::params::hiera_remote,
  $puppet_base   = $puppet_master::params::puppet_base,
  $puppet_remote = $puppet_master::params::puppet_remote,
  $purge_hosts   = $puppet_master::params::purge_hosts,
  $r10k_enabled  = $puppet_master::params::r10k_enabled,
  $vip           = $puppet_master::params::vip,
) {

  class { 'puppet_master::compile':
    ca_enabled    => true,
    dns_alt_names => $dns_alt_names,
    hiera_base    => $hiera_base,
    hiera_remote  => $hiera_remote,
    master        => $::clientcert,
    puppet_base   => $puppet_base,
    puppet_remote => $puppet_remote,
    r10k_enabled  => $r10k_enabled,
    vip           => $vip,
  }

  # doing this as auth_conf module is a pain in the arse
  file { '/etc/puppetlabs/puppet/auth.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/puppet_master/auth.conf',
    notify  => Service['pe-httpd'],
    require => Class['puppet_master::compile'],
  }
}
