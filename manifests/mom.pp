class puppet_master::mom (
  $r10k_enabled  = true,
  $puppet_remote = undef,
  $puppet_base   = "${::settings::confdir}/environments",
  $hiera_remote  = undef,
  $hiera_base    = "${::settings::confdir}/hieradata",
) {

  class { 'puppet_master':
    ca_enabled    => true,
    r10k_enabled  => $r10k_enabled,
    puppet_remote => $puppet_remote,
    puppet_base   => $puppet_base,
    hiera_remote  => $hiera_remote,
    hiera_base    => $hiera_base,
    vip           => $::fqdn,
  }

  # doing this as auth_conf module is a pain in the arse
  file { '/etc/puppetlabs/puppet/auth.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/puppet_master/auth.conf',
    notify  => Service['pe-httpd'],
    require => Class['puppet_master'],
  }
}
