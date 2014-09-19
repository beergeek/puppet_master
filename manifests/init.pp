# == Class: puppet_master
#
# Full description of class puppet_master here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { puppet_master:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class puppet_master (
  $master        = $::fqdn,
  $ca_enabled    = false,
  $ca_server     = undef,
  $server        = $::settings::server,
  $r10k_enabled  = true,
  $puppet_remote = undef,
  $puppet_base   = "${::settings::confdir}/environments",
  $hiera_remote  = undef,
  $hiera_base    = "${::settings::confdir}/hieradata",
  $hiera_file    = 'puppet:///modules/puppet_master/hiera.yaml',
  $vip           = "puppet.${::domain}",
  $purge_hosts   = false,
  $dns_alt_names = [
    $::hostname,
    $::fqdn,
    'puppet',
    "puppet.${::domain}",
  ],
)  {

  validate_bool($ca_enabled)
  validate_bool($r10k_enabled)
  validate_array($dns_alt_names)
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
      purge => true,
    }
  }

  Host <<| tag == 'masters' |>>

  #export for PuppetDB and Console certificate
  @@puppet_master::console::whitelist_entry { $::fqdn: }
  @@puppet_master::puppetdb::whitelist_entry { $::fqdn: }

  # manage our Hiera config
  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    source => $hiera_file,
  }

  # manage the main site.pp (as we are managing the filebucket
  file { '/etc/puppetlabs/puppet/manifests/site.pp':
    ensure  => file,
    content => template('puppet_master/site.pp.erb'),
  }

  # managed r10k if desired
  if $r10k_enabled {
    if ! $puppet_remote or $hiera_remote {
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
    value   => "${::settings::confdir}/environments",
  }

  ini_setting { 'puppet_basemodulepath':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'basemodulepath',
    value   => "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules",
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

  # call the pe_httpd class to manage Puppet Apache
  class { 'puppet_master::pe_httpd':
    ca_enabled    => $ca_enabled,
    server        => $server,
    dns_alt_names => $dns_alt_names,
  }

}
