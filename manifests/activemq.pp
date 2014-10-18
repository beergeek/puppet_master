# == Class: puppet_master::activemq
#
# Class to manage ActiveMQ services..
#
# === Parameters
#
# [*keystore_passwd*]
#   Password for Java Keystore.
#   No default!
#
# [*export_keys*]
#   Boolean value to determine if the exported ActiveMQ keys are imported.
#   Default is in puppet_master::params
#   Default is true.
#
# === Examples
#
#  class { 'puppet_master::activemq':
#    keystore_passwd => 'g@ry_w3@ars_fl0ppy_sh03s',
#    export_keys     => true,
#  }
#
# === Authors
#
# Brett Gray <brett.gray@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Brett Gray.
#
class puppet_master::activemq (
  $keystore_passwd,
  $export_keys      = $puppet_master::params::export_keys,
) inherits puppet_master::params {

  #validation
  validate_bool($export_keys)
  if ! defined(Class['pe_mcollective::activemq']) {
    fail('The `pe_mcollective::activemq` class must be included in the catalog')
  }

  File {
    owner => 'pe-puppet',
    group => 'pe-puppet',
    mode  => '0644',
  }

  Java_ks {
    path     => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    password => $keystore_passwd,
    notify   => Service['pe-activemq'],
  }


  # Welcome to crazy town for ActiveMQ and MCO!
  if $export_keys {

    file { '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-mcollective-servers.pem':
      ensure => file,
      content => file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-mcollective-servers.pem'),
    }

    file { '/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-mcollective-servers.pem':
      ensure => file,
      content => file('/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-mcollective-servers.pem'),
      mode    => '0640',
    }

    file { '/etc/puppetlabs/puppet/ssl/certs/pe-internal-mcollective-servers.pem':
      ensure => file,
      content => file('/etc/puppetlabs/puppet/ssl/certs/pe-internal-mcollective-servers.pem'),
    }

    file { '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-peadmin-mcollective-client.pem':
      ensure => file,
      content => file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-peadmin-mcollective-client.pem'),
    }

    file { '/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-puppet-console-mcollective-client.pem':
      ensure  => file,
      content => file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-puppet-console-mcollective-client.pem'),
    }
  }

  java_ks { 'activemq:truststore':
    ensure       => latest,
    certificate  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    target       => '/etc/puppetlabs/activemq/broker.ts',
    trustcacerts => true,
    before       => File['/etc/puppetlabs/activemq/broker.ts'],
  }

  java_ks { 'activemq:keystore':
    ensure      => latest,
    target      => '/etc/puppetlabs/activemq/broker.ks',
    certificate => "/etc/puppetlabs/puppet/ssl/certs/${clientcert}.pem",
    private_key => "/etc/puppetlabs/puppet/ssl/private_keys/${clientcert}.pem",
    before      => File['/etc/puppetlabs/activemq/broker.ks'],
  }

  file { '/etc/puppetlabs/activemq/broker.ts':
    ensure => file,
    owner  => 'root',
    group  => 'pe-activemq',
    mode   => '0640',
  }

  file { '/etc/puppetlabs/activemq/broker.ks':
    ensure => file,
    owner  => 'root',
    group  => 'pe-activemq',
    mode   => '0640',
  }
}
