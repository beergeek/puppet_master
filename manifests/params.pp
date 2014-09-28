class puppet_master::params {

  $all_in_one         = true
  $ca_enabled         = false
  $ca_server          = $::settings::server
  $default_whitelist  = [$::fqdn, 'pe-internal-dashbaord']
  $export_keys        = true
  $hiera_base         = "${::settings::confdir}/hieradata"
  $hiera_file         = 'puppet:///modules/puppet_master/hiera.yaml'
  $hiera_remote       = undef
  $manage_console     = false
  $manage_master      = true
  $master             = $::fqdn
  $puppet_base        = "${::settings::confdir}/environments"
  $puppet_remote      = undef
  $purge_hosts        = false
  $r10k_enabled       = true
  $server             = $::settings::server
  $vip                = "puppet.${::domain}"
  $dns_alt_names      = [
    $::hostname,
    $::fqdn,
    'puppet',
    "puppet.${::domain}"
  ]
}
