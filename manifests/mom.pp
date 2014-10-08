# == Class: puppet_master::mom
#
# Class to manage the Puppet Master of Masters node.
#
# === Parameters
#
# [*dns_alt_names*]
#   Array of DNS Alt Names used for the server alias within the puppetmaster.conf fir pe-httpd
#   Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]
#   Required.
#
# [*hiera_backends*]
#   Array of backends to include in the hiera.yaml file.
#   Default is ['yaml'].
#
# [*hiera_base*]
#   Hiera data directory on node.
#   Default is "${::settings::confdir}/hieradata".
#
# [*hiera_file*]
#   Location of source for Hiera config file.
#   Defaults to 'puppet:///modules/puppet_master/hiera.yaml'.
#
# [*hiera_hierarchy*]
#   Hierarchy to be included in the hiera.yaml file
#   Default is ['%{clientcert}','global'].
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
#  class { 'puppet_master::mom':
#     dns_alt_names   => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
#     hiera_backends  => ['yaml'],
#     hiera_base      => '/etc/puppetlabs/puppet/hieradata',
#     hiera_file      => 'puppet:///modules/puppet_master/hiera.yaml',
#     hiera_hierarchy => ['%{clientcert}','global'],
#     hiera_remote    => 'https://github.com/glarizza/hiera.git',
#     puppet_base     => '/etc/puppetlabs/puppet/environments',
#     puppet_remote   => 'https://github.com/glarizza/puppet.git',
#     purge_hosts     => false,
#     r10k_enabled    => true,
#     vip             => 'puppet.puppetlabs.local',
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
  $dns_alt_names    = $puppet_master::params::dns_alt_names,
  $hiera_backends   = $puppet_master::params::hiera_backends,
  $hiera_base       = $puppet_master::params::hiera_base,
  $hiera_file       = $puppet_master::params::hiera_file,
  $hiera_hierarchy  = $puppet_master::params::hiera_hierarchy,
  $hiera_remote     = $puppet_master::params::hiera_remote,
  $puppet_base      = $puppet_master::params::puppet_base,
  $puppet_remote    = $puppet_master::params::puppet_remote,
  $purge_hosts      = $puppet_master::params::purge_hosts,
  $r10k_enabled     = $puppet_master::params::r10k_enabled,
  $vip              = $puppet_master::params::vip,
) {

  class { 'puppet_master::compile':
    ca_enabled      => true,
    dns_alt_names   => $dns_alt_names,
    hiera_backends  => $hiera_backends,
    hiera_base      => $hiera_base,
    hiera_hierarchy => $hiera_hierarchy
    hiera_remote    => $hiera_remote,
    master          => $::clientcert,
    puppet_base     => $puppet_base,
    puppet_remote   => $puppet_remote,
    r10k_enabled    => $r10k_enabled,
    vip             => $vip,
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
