class puppet_master::mom (
) {

  class { 'puppet_master':
    ca_enabled => true,
  }

  # doing this as auth_conf module is a pain in the arse
  file { '/etc/puppetlabs/puppet/auth.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/puppet_master/auth.conf',
  }
}
