class puppet_master::pe_httpd (
  $ca_enabled    = false,
  $server        = $::settings::server,
  $manage_master  = true,
  $manage_console = false,
  $dns_alt_names = [
    $::hostname,
    $::fqdn,
    'puppet',
    "puppet.${::domain}",
  ],
) {

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
