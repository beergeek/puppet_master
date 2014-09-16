class puppet_master::puppetdb (
  $default_whitelist = [$::fqdn, 'pe-internal-dashbaord']
) {

  file { '/etc/puppetlabs/puppetdb/certificate_whitelist':
    ensure => file,
    owner  => 'pe-puppetdb',
    group  => 'pe-puppetdb',
    mode   => '0600',
  }

  puppet_master::puppetdb::whitelist_entry { $default_whitelist: }

  Puppet_master::Puppetdb::Whitelist_entry <<| |>>
}
