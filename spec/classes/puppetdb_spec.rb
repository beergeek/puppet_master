require 'spec_helper'
describe 'puppet_master::puppetdb' do
  before do
    Puppet[:confdir]    = '/etc/puppetlabs/puppet'
    Puppet[:server]     = 'ca.puppetlabs.local'
  end

  context 'with defaults and required for all parameters' do
    let(:facts) {
      {
        :domain         => 'puppetlabs.local',
        :fqdn           => 'ca.puppetlabs.local',
        :hostname       => 'ca',
        :osfamily       => 'RedHat',
        :puppetversion  => '3.6.2 (Puppet Enterprise 3.3.2)',
        :concat_basedir => '/tmp',
      }
    }

    it { should contain_class('puppet_master::puppetdb') }

    it {
      should contain_file('/etc/puppetlabs/puppetdb/certificate-whitelist').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppetdb',
        'group'   => 'pe-puppetdb',
        'mode'    => '0600',
      )
    }
  end
end
