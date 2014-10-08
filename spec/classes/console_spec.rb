require 'spec_helper'
describe 'puppet_master::console' do
  before do
    Puppet[:confdir]    = '/etc/puppetlabs/puppet'
    Puppet[:server]     = 'ca.puppetlabs.local'
  end

  context 'with defaults and required for all parameters' do
    let(:pre_condition) { 'class {"puppet_master::httpd": }' }
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

    it { should contain_class('puppet_master::console') }

    it {
      should contain_concat('/etc/puppetlabs/console-auth/certificate_authorization.yml').with(
        'owner'           => 'pe-auth',
        'group'           => 'puppet-dashboard',
        'mode'            => '0640',
        'ensure_newline'  => false,
      )
    }

    it {
      should contain_concat__fragment('top').with(
        'target'  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
        'content' => "---\n",
        'order'   => '01',
      )
    }

    it {
      should contain_concat__fragment('pe-internal-dashbaord').with(
        'target'  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
        'content' => "pe-internal-dashbaord:\n  role: read-write\n",
        'order'   => '02',
      )
    }
  end
end
