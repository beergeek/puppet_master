# == Class: puppet_master::compile
#
# Class to manage Puppet compile masters in a split installation with several compile/ActiveMQ masters
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
#   Array of DNS Alt Names used for the server alias within the puppetmaster.conf for pe-httpd
#   Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]
#
# [*hiera_backends*]
#   Array of backends to include in the hiera.yaml file.
#   Default is ['yaml'].
#
# [*hiera_base*]
#   Hiera data directory on node.
#   Default is "${::settings::confdir}/hieradata".
#
# [*hiera_template*]
#   Location of templatee for Hiera config file.
#   Defaults to 'puppet_master/hiera.yaml.erb'.
#
# [*hiera_hierarchy*]
#   Hierarchy to be included in the hiera.yaml file
#   Default is ['%{clientcert}','global'].
#
# [*hiera_remote*]
#   URL of the remote GIT repo for Hiera.
#   Required if ca_enabled is false.
#
# [*master*]
#   Name of the Puppet master this node will use as its server.  Should be the Master of Masters.
#   Default os $::fqdn
#   Required.
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
#  class { puppet_master::compile':
#     ca_enabled      => false,
#     ca_server       => 'ca.puppetlabs.local'
#     dns_alt_names   => ['com1','com1.puppetlabs.local','puppet','puppet.puppetlabs.local'],
#     hiera_backends  => ['yaml'],
#     hiera_base      => '/etc/puppetlabs/puppet/hieradata',
#     hiera_hierarchy => ['%{clientcert}','global'],
#     hiera_remote    => 'https://github.com/glarizza/hiera.git',
#     hiera_template  => 'puppet_master/hiera.yaml.erb',
#     master          => 'ca.puppetlabs.local',
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
class puppet_master::compile (
  $ca_enabled       = $puppet_master::params::ca_enabled,
  $ca_server        = $puppet_master::params::ca_server,
  $dns_alt_names    = $puppet_master::params::dns_alt_names,
  $hiera_base       = $puppet_master::params::hiera_base,
  $hiera_backends   = $puppet_master::params::hiera_backends,
  $hiera_template   = $puppet_master::params::hiera_template,
  $hiera_hierarchy  = $puppet_master::params::hiera_hierarchy,
  $hiera_remote     = $puppet_master::params::hiera_remote,
  $master           = $puppet_master::params::master,
  $puppet_base      = $puppet_master::params::puppet_base,
  $puppet_remote    = $puppet_master::params::puppet_remote,
  $purge_hosts      = $puppet_master::params::purge_hosts,
  $r10k_enabled     = $puppet_master::params::r10k_enabled,
  $vip              = $puppet_master::params::vip,
) inherits puppet_master::params {

  validate_bool($ca_enabled)
  validate_bool($purge_hosts)
  validate_bool($r10k_enabled)
  validate_array($dns_alt_names)
  validate_array($hiera_backends)
  validate_array($hiera_hierarchy)
  validate_absolute_path($puppet_base)
  validate_absolute_path($hiera_base)

  File {
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0644',
  }

  @@host { $::fqdn:
    ensure       => 'present',
    host_aliases => [$::hostname],
    ip           => $::ipaddress,
    tag          => 'masters',
  }

  host { 'localhost':
    ensure       => 'present',
    host_aliases => ['localhost.localdomain', 'localhost4', 'localhost4.localdomain4'],
    ip           => '127.0.0.1',
  }

  if $purge_hosts {
    resources { 'host':
      purge => $purge_hosts,
    }
  }

  Host <<| tag == 'masters' |>>

  #export for PuppetDB and Console certificate
  @@puppet_master::console::whitelist_entry { $::clientcert: }
  @@puppet_master::puppetdb::whitelist_entry { $::clientcert: }

  # manage our Hiera config
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => template($hiera_template),
  }

  # manage the main site.pp (as we are managing the filebucket
  file { '/etc/puppetlabs/puppet/manifests/site.pp':
    ensure  => file,
    content => template('puppet_master/site.pp.erb'),
  }

  # managed r10k if desired
  if $r10k_enabled {
    if ! ($puppet_remote and $hiera_remote) {
      fail("r10k requires a remote repo for puppet and hiera")
    }
    validate_absolute_path($puppet_base)
    validate_absolute_path($hiera_base)
    class { 'r10k':
      sources           => {
        'puppet' => {
          'remote'  => $puppet_remote,
          'basedir' => $puppet_base,
          'prefix'  => false,
        },
        'hiera'  => {
          'remote'  => $hiera_remote,
          'basedir' => $hiera_base,
          'prefix'  => false
        }
      },
      purgedirs         => [$puppet_base,$hiera_base],
      manage_modulepath => false,
    }
  }

  # we are going to use directory envionrments as default
  ini_setting { 'puppet_environmentpath':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'environmentpath',
    value   => '$confdir/environments',
  }

  ini_setting { 'puppet_basemodulepath':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'basemodulepath',
    value   => '$confdir/modules:/opt/puppet/share/puppet/modules',
  }

  ini_setting { 'puppet_server':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'agent',
    setting => 'server',
    value   => $master,
  }

  ini_setting { 'puppet_ca':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'ca',
    value   => $ca_enabled,
  }

  # if we are not the CA we need to provide the address
  if $ca_enabled == false {
    ini_setting { 'puppet_ca_server':
      ensure  => present,
      path    => '/etc/puppetlabs/puppet/puppet.conf',
      section => 'main',
      setting => 'ca_server',
      value   => $ca_server,
    }
  }

  # call the httpd class to manage Puppet Apache
  class { 'puppet_master::httpd':
    ca_enabled    => $ca_enabled,
    ca_server     => $ca_server,
    dns_alt_names => $dns_alt_names,
  }

}
