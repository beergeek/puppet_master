define puppet_master::whitelist_entry {

  if ! defined(File_line[$name]) {
    file_line { "puppetdb_whitelist:${name}":
      path    => '/etc/puppetlabs/puppetdb/certificate-whitelist',
      line    => $name,
      notify  => Service['pe-puppetdb'],
      require => File['/etc/puppetlabs/puppetdb/certificate-whitelist'],
    }
  }

}
