class puppet_master::activemq (
  $keystore_passwd,
  $export_keys = true,
) {

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

  java_ks { 'puppetca:truststore':
    ensure       => latest,
    path         => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    certificate  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    target       => '/etc/puppetlabs/activemq/broker.ts',
    password     => $keystore_passwd,
    trustcacerts => true,
    before       => File['/etc/puppetlabs/activemq/broker.ts'],
    notify       => Service['pe-activemq'],
  }

  java_ks { "${::clientcert}:keystore":
    ensure      => latest,
    path        => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    target      => '/etc/puppetlabs/activemq/broker.ks',
    certificate => "/etc/puppetlabs/puppet/ssl/certs/${clientcert}.pem",
    private_key => "/etc/puppetlabs/puppet/ssl/private_keys/${clientcert}.pem",
    password    => $keystore_passwd,
    before      => File['/etc/puppetlabs/activemq/broker.ks'],
    notify      => Service['pe-activemq'],
  }

  file { '/etc/puppetlabs/activemq/broker.ts':
    owner   => 'root',
    group   => 'pe-activemq',
    mode    => '0640',
  }

  file { '/etc/puppetlabs/activemq/broker.ks':
    owner  => 'root',
    group  => 'pe-activemq',
    mode   => '0640',
  }
}
