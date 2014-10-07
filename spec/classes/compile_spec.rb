require 'spec_helper'
describe 'puppet_master::compile' do
  Puppet.settings[:confdir] = '/etc/puppetlabs/puppet'

  context 'with defaults for all parameters' do
    let(:facts) {
      {
        :fqdn           => 'com1.puppetlabs.vm',
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
        'source' => 'puppet:///modules/puppet_master/hiera.yaml',
      )
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
        'value'   => 'com1.puppetlabs.vm',
      )
    }
  end
end
