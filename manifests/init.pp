class puppet_master (
  $master        = $::fqdn,
  $ca_enabled    = false,
  $ca_server     = undef,
  $server        = $::settings::server,
  $r10k_enabled  = true,
  $puppet_remote = undef,
  $hiera_remote  = undef,
  $dns_alt_names = [
    $::hostname,
    $::fqdn,
    'puppet',
    "puppet.${::domain}",
  ],
)  {

  validate_bool($ca_enabled)

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

  #resources { 'host':
  #  purge => true,
  #}

  Host <<| tag == 'masters' |>>

  #export for PuppetDB and Console certificate
  @@puppet_master::console::whitelist_entry { $::fqdn: }
  @@puppet_master::puppetdb::whitelist_entry { $::fqdn: }

  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/puppet_master/hiera.yaml',
  }

  if $r10k_enabled {
    class { 'r10k':
      sources           => {
        'puppet' => {
          'remote'  => 'https://github.com/beergeek/puppet-env.git',
          'basedir' => "${::settings::confdir}/environments",
          'prefix'  => false,
        },
        'hiera'  => {
          'remote'  => 'https://github.com/beergeek/hiera-env.git',
          'basedir' => "${::settings::confdir}/hieradata",
          'prefix'  => false
        }
      },
      purgedirs         => ["${::settings::confdir}/environments","${::settings::confdir}/hieradata"],
      manage_modulepath => false,
    }
  }

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

  if $ca_enabled == false {
    ini_setting { 'puppet_ca_server':
      ensure  => present,
      path    => '/etc/puppetlabs/puppet/puppet.conf',
      section => 'main',
      setting => 'ca_server',
      value   => $ca_server,
    }
  }

  class { 'puppet_master::pe_httpd':
    ca_enabled    => $ca_enabled,
    server        => $server,
    dns_alt_names => $dns_alt_names,
  }


  # Welcome to crazy town for ActiveMQ and MCO!
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
  java_ks { 'puppetca:truststore':
    ensure       => latest,
    path         => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    certificate  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
    target       => '/etc/puppetlabs/activemq/broker.ts',
    password     => 'puppet',
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
    password    => 'puppet',
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
