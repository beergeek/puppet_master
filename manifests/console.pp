class puppet_master::console (
  $default_whitelist = [$::fqdn, 'pe-internal-dashbaord']
) {

  if ! defined(Class['puppet_master::pe_httpd']) {
    class { 'puppet_master::pe_httpd':
     ca_enabled => true,
    }
  }

  $role = 'read-write'

  concat { '/etc/puppetlabs/console-auth/certificate_authorization.yml':
    owner          => 'pe-auth',
    group          => 'puppet-dashboard',
    mode           => '0640',
    ensure_newline => false,
    notify         => Service['pe-httpd'],
  }

  concat::fragment { 'top':
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => "---\n",
    order   => '01',
  }

  concat::fragment { $::fqdn:
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => "${::fqdn}:\n  role: read-write\n",
    order   => '02',
  }

  concat::fragment { 'pe-internal-dashbaord':
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => "pe-internal-dashbaord:\n  role: read-write\n",
    order   => '02',
  }

  Puppet_master::Console::Whitelist_entry <<| |>>

}
