require 'spec_helper'
describe 'puppet_master::mom' do
  before do
    Puppet[:confdir]    = '/etc/puppetlabs/puppet'
    Puppet[:server]     = 'ca.puppetlabs.local'
    Puppet[:clientcert] = 'ca.puppetlabs.local'
  end

  context 'with defaults and required for all parameters' do
    let(:facts) {
      {
        :domain         => 'puppetlabs.local',
        :fqdn           => 'ca.puppetlabs.local',
        :hostname       => 'ca',
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

    it { should contain_class('puppet_master::mom') }

    it {
      should contain_class('puppet_master::compile').with(
        'ca_enabled'      => true,
        'dns_alt_names'   => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
        'hiera_backends'  => ['yaml'],
        'hiera_base'      => '/etc/puppetlabs/puppet/hieradata',
        'hiera_hierarchy' => ['#{clientcert}','global'],
        'hiera_remote'    => 'https://github.com/glarizza/hiera.git',
        'hiera_template'  => 'puppet_master/hiera.yaml.erb',
        'master'          => 'ca.puppetlabs.local',
        'puppet_base'     => '/etc/puppetlabs/puppet/environments',
        'puppet_remote'   => 'https://github.com/glarizza/puppet.git',
        'r10k_enabled'    => true,
        'vip'             =>'puppet.puppetlabs.local',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/auth.conf').with(
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'source' => 'puppet:///modules/puppet_master/auth.conf',
      )
    }
  end
end
