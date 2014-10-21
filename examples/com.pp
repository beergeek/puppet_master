class profiles::com {

  $all_in_one       = hiera('profiles::com::all_in_one')
  $ca_enabled       = hiera('profiles::com::ca_enabled')
  $ca_server        = hiera('profiles::com::ca_server')
  $dns_alt_names    = hiera('profiles::com::dns_alt_names')
  $dump_path        = hiera('profiles::com::dump_path')
  $enable_firewall  = hiera('profiles::com::enable_firewall')
  $hiera_backends   = hiera('profiles::com::hiera_backends')
  $hiera_base       = hiera('profiles::com::hiera_base')
  $hiera_hierarchy  = hiera('profiles::com::hiera_hierarchy')
  $hiera_remote     = hiera('profiles::com::hiera_remote')
  $hiera_template   = hiera('profiles::com::hiera_template')
  $master           = hiera('profiles::com::master')
  $puppet_base      = hiera('profiles::com::puppet_base')
  $puppet_remote    = hiera('profiles::com::puppet_remote')
  $purge_hosts      = hiera('profiles::com::purge_hosts')
  $r10k_enabled     = hiera('profiles::com::r10k_enabled')
  $vip              = hiera('profiles::com::vip')
  $export_keys      = hiera('profiles::com::export_keys')
  $keystore_passwd  = hiera('profiles::com::keystore_passwd')

  if $enable_firewall {
    # include firewall rule
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

    firewall { '100 allow activemq access':
      port   => '61616',
      proto  => 'tcp',
      action => 'allow',
    }
  }

  class { 'puppet_master::compile':
     ca_enabled      => $ca_enabled,
     ca_server       => $ca_server,
     dns_alt_names   => $dns_alt_names,
     hiera_backends  => $hiera_backends,
     hiera_base      => $hiera_base,
     hiera_hierarchy => $hiera_hierarchy,
     hiera_remote    => $hiera_remote,
     hiera_template  => $hiera_template,
     master          => $master,
     puppet_base     => $puppet_base,
     puppet_remote   => $puppet_remote,
     purge_hosts     => $purge_hosts,
     r10k_enabled    => $r10k_enabled,
     vip             => $vip,
  }

  class { 'puppet_master::activemq':
    keystore_passwd => $keystore_passwd,
    export_keys     => $export_keys,
  }

}
