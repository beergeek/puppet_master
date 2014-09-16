class puppet_master::mom (
) {

  file { '/etc/puppetlabs/puppet/auth.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profiles/auth.conf',
  }

}
