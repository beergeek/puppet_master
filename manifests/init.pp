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

}
