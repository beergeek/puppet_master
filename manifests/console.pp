class puppet_master::console (
  $default_whitelist = [$::fqdn, 'pe-internal-dashbaord']
) {

  $role = 'read-write'

  concat { '/etc/puppetlabs/console-auth/certificate_authorization.yml':
    owner          => 'pe-auth',
    group          => 'puppet-dashboard',
    mode           => '0640',
    ensure_newline => false,
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
