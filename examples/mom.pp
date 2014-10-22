class profiles::mom {

  $all_in_one       = hiera('profiles::mom::all_in_one')
  $dns_alt_names    = hiera('profiles::mom::dns_alt_names')
  $dump_path        = hiera('profiles::mom::dump_path')
  $enable_firewall  = hiera('profiles::mom::enable_firewall')
  $hiera_backends   = hiera('profiles::mom::hiera_backends')
  $hiera_base       = hiera('profiles::mom::hiera_base')
  $hiera_hierarchy  = hiera('profiles::mom::hiera_hierarchy')
  $hiera_remote     = hiera('profiles::mom::hiera_remote')
  $hiera_template   = hiera('profiles::mom::hiera_template')
  $puppet_base      = hiera('profiles::mom::puppet_base')
  $puppet_remote    = hiera('profiles::mom::puppet_remote')
  $purge_hosts      = hiera('profiles::mom::purge_hosts')
  $r10k_enabled     = hiera('profiles::mom::r10k_enabled')

  # include firewall rule
  if $enable_firewall {
    firewall { '100 allow puppet access':
      port   => '8140',
      proto  => 'tcp',
      action => 'accept',
    }

    firewall { '100 allow mcollective access':
      port   => '61613',
      proto  => 'tcp',
      action => 'allow',
    }

    firewall { '100 allow puppetdb access':
      port   => '8081',
      proto  => 'tcp',
      action => 'allow',
    }

    firewall { '100 allow console access':
      port   => '443',
      proto  => 'tcp',
      action => 'allow',
    }
  }

  class { 'puppet_master::mom':
      dns_alt_names   => $dns_alt_names,
      hiera_backends  => $hiera_backends,
      hiera_base      => $hiera_base,
      hiera_hierarchy => $hiera_hierarchy,
      hiera_remote    => $hiera_remote,
      hiera_template  => $hiera_template,
      puppet_base     => $puppet_base,
      puppet_remote   => $puppet_remote,
      purge_hosts     => $purge_hosts,
      r10k_enabled    => $r10k_enabled,
  }

  class { 'puppet_master::puppetdb':
    all_in_one => $all_in_one,
  }

  class { 'puppet_master::console':
    all_in_one => $all_in_one,
  }

  # posgresq dumps
  file { 'dump_directory':
    ensure => directory,
    path   => $dump_path,
    owner  => 'pe-postgres',
    group  => 'root',
    mode   => '0755',
  }

  cron { 'puppet_console_dumps':
    ensure  => present,
    command => "su - pe-postgres -s /bin/bash -c '/opt/puppet/bin/pg_dump -Fc -C -c -p 5432 console' > ${dump_path}/console_`date +'%Y%m%d%H%M'`",
    user    => 'root',
    hour    => '23',
    minute  => '30',
    day     => '*',
    require => File['dump_directory'],
  }

  cron { 'puppet_console_auth_dumps':
    ensure  => present,
    command => "su - pe-postgres -s /bin/bash -c '/opt/puppet/bin/pg_dump -Fc -C -c -p 5432 console_auth' > ${dump_path}/console_auth_`date +'%Y%m%d%H%M'`",
    user    => 'root',
    hour    => '23',
    minute  => '30',
    day     => '*',
    require => File['dump_directory'],
  }

  cron { 'puppet_puppetdb_dumps':
    ensure  => present,
    command => "su - pe-postgres -s /bin/bash -c '/opt/puppet/bin/pg_dump -Fc -C -c -p 5432 puppetdb' > ${dump_path}/puppetdb_`date +'%Y%m%d%H%M'`",
    user    => 'root',
    hour    => '23',
    minute  => '30',
    day     => '*',
    require => File['dump_directory'],
  }

}
