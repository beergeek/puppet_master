require 'spec_helper'
describe 'puppet_master::compile' do
  before do
    Puppet[:confdir] = '/etc/puppetlabs/puppet'
    Puppet[:server] = 'ca.puppetlabs.local'
  end

  # normal compile master
  context 'with defaults and required for all parameters' do
    let(:facts) {
      {
        :domain         => 'puppetlabs.local',
        :fqdn           => 'com1.puppetlabs.local',
        :hostname       => 'com1',
        :osfamily       => 'RedHat',
        :puppetversion  => '3.6.2 (Puppet Enterprise 3.3.2)',
      }
    }
    let(:params) {
      {
        :hiera_remote  => 'https://github.com/glarizza/hiera.git',
        :puppet_remote => 'https://github.com/glarizza/puppet.git',
      }
    }

    it { should contain_class('puppet_master::compile') }

    it {
      should contain_host('localhost').with(
        'ensure'        => 'present',
        'host_aliases'  => ['localhost.localdomain', 'localhost4', 'localhost4.localdomain4'],
        'ip'            => '127.0.0.1',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/hiera.yaml').with(
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
      ).with_content(/backends:\n  - yaml/)
      .with_content(/hierarchy:\n  - "%{clientcert}"/)
    }

    it {
      should contain_class('r10k').with(
        'sources'           => {
          'puppet' => {
            'remote'  => 'https://github.com/glarizza/puppet.git',
            'basedir' => '/etc/puppetlabs/puppet/environments',
            'prefix'  => false,
          },
          'hiera'  => {
            'remote'  => 'https://github.com/glarizza/hiera.git',
            'basedir' => '/etc/puppetlabs/puppet/hieradata',
            'prefix'  => false
          }
        },
        'purgedirs'         => ['/etc/puppetlabs/puppet/environments', '/etc/puppetlabs/puppet/hieradata'],
        'manage_modulepath' => false,
      )
    }

    it {
      should contain_ini_setting('puppet_environmentpath').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'environmentpath',
        'value'   => '$confdir/environments',
      )
    }

    it {
      should contain_ini_setting('puppet_basemodulepath').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'basemodulepath',
        'value'   => '$confdir/modules:/opt/puppet/share/puppet/modules',
      )
    }

    it {
      should contain_ini_setting('puppet_server').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'agent',
        'setting' => 'server',
        'value'   => 'com1.puppetlabs.local',
      )
    }

    it {
      should contain_ini_setting('puppet_ca').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'master',
        'setting' => 'ca',
        'value'   => false,
      )
    }

    it {
      should contain_ini_setting('puppet_ca_server').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'ca_server',
        'value'   => 'ca.puppetlabs.local',
      )
    }

    it {
      should contain_class('puppet_master::httpd').with(
        'ca_enabled'    => false,
        'ca_server'     => 'ca.puppetlabs.local',
        'dns_alt_names' => ['com1','com1.puppetlabs.local','puppet','puppet.puppetlabs.local'],
      )
    }
  end

  # for MOM
  context 'with defaults and required for parameters for MOM' do
    let(:facts) {
      {
        :domain         => 'puppetlabs.local',
        :hostname       => 'ca',
        :fqdn           => 'ca.puppetlabs.local',
        :osfamily       => 'RedHat',
        :puppetversion  => '3.6.2 (Puppet Enterprise 3.3.2)',
      }
    }
    let(:params) {
      {
        :ca_enabled    => true,
        :hiera_remote  => 'https://github.com/glarizza/hiera.git',
        :puppet_remote => 'https://github.com/glarizza/puppet.git',
      }
    }

    it { should contain_class('puppet_master::compile') }

    it {
      should contain_host('localhost').with(
        'ensure'        => 'present',
        'host_aliases'  => ['localhost.localdomain', 'localhost4', 'localhost4.localdomain4'],
        'ip'            => '127.0.0.1',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/hiera.yaml').with(
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
      ).with_content(/backends:\n  - yaml/)
      .with_content(/hierarchy:\n  - "%{clientcert}"/)
    }

    it {
      should contain_class('r10k').with(
        'sources'           => {
          'puppet' => {
            'remote'  => 'https://github.com/glarizza/puppet.git',
            'basedir' => '/etc/puppetlabs/puppet/environments',
            'prefix'  => false,
          },
          'hiera'  => {
            'remote'  => 'https://github.com/glarizza/hiera.git',
            'basedir' => '/etc/puppetlabs/puppet/hieradata',
            'prefix'  => false
          }
        },
        'purgedirs'         => ['/etc/puppetlabs/puppet/environments', '/etc/puppetlabs/puppet/hieradata'],
        'manage_modulepath' => false,
      )
    }

    it {
      should contain_ini_setting('puppet_environmentpath').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'environmentpath',
        'value'   => '$confdir/environments',
      )
    }

    it {
      should contain_ini_setting('puppet_basemodulepath').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'basemodulepath',
        'value'   => '$confdir/modules:/opt/puppet/share/puppet/modules',
      )
    }

    it {
      should contain_ini_setting('puppet_server').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'agent',
        'setting' => 'server',
        'value'   => 'ca.puppetlabs.local',
      )
    }

    it {
      should contain_ini_setting('puppet_ca').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'master',
        'setting' => 'ca',
        'value'   => true,
      )
    }

    it {
      should_not contain_ini_setting('puppet_ca_server').with(
        'ensure'  => 'present',
        'path'    => '/etc/puppetlabs/puppet/puppet.conf',
        'section' => 'main',
        'setting' => 'ca_server',
        'value'   => 'ca.puppetlabs.local',
      )
    }

    it {
      should contain_class('puppet_master::httpd').with(
        'ca_enabled'    => true,
        'dns_alt_names' => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
      )
    }
  end
end
