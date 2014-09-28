# == Define Type: puppet_master::puppetdb::whitelist_entry
#
# Defined type that creates entries for the PuppetDB whitelist
#
# === Examples
#
#  puppet_master::puppetdb::whitelist_entry { 'cbr1uberupcom3.uberu.local':
#  }
#
# === Authors
#
# Brett Gray <brett.gray@puppetlabs.vm>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
define puppet_master::puppetdb::whitelist_entry {

  if ! defined(File_line[$name]) {
    file_line { "puppetdb_whitelist:${name}":
      path    => '/etc/puppetlabs/puppetdb/certificate-whitelist',
      line    => $name,
      notify  => Service['pe-puppetdb'],
      require => File['/etc/puppetlabs/puppetdb/certificate-whitelist'],
    }
  }

}
