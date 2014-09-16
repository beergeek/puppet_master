class puppet_master::console (
  $default_whitelist = [$::fqdn, 'pe-internal-dashbaord']
) {

  concat { '/etc/puppetlabs/console-auth/certificate_authorization.yml':
    owner          => 'pe-auth',
    group          => 'puppet-dashbaord',
    mode           => '0640',
    ensure_newline => true,
  }

  concat::fragment { 'top':
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => '---',
    order   => 1,
  }

  concat::fragment { $default_whitelist:
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => template('puppet_master/console_whitelist.erb'),
    order   => 2,
  }

  Puppet_master::Console::Whitelist_entry <<| |>>

}
