class puppet_master (
  $master     = $::fqdn,
  $ca_enabled = false,
  $ca_server  = undef,
)  {

  validate_bool($ca_enabled)

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

  resources { 'host':
    purge => true,
  }

  Host <<| tag == 'masters' |>>

  file { '/etc/puppetlabs/puppet/hiera.yaml':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/puppet_master/hiera.yaml',
  }

  class { 'r10k':
    sources           => {
      'puppet' => {
        'remote'  => 'https://uber-dev:iw9a28AUw2832hau8@github.com/uberglobal/puppet.git',
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
      'hiera'  => {
        'remote'  => 'https://uber-dev:iw9a28AUw2832hau8@github.com/uberglobal/hiera.git',
        'basedir' => "${::settings::confdir}/hieradata",
        'prefix'  => false
      }
    },
    purgedirs         => ["${::settings::confdir}/environments","${::settings::confdir}/hieradata"],
    manage_modulepath => false,
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

  class { 'pe_httpd':
    server    => $::settings::server,
    ca_server => $ca_enabled,
  }

}
