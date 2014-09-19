require 'spec_helper'
describe 'puppet_master' do

  context 'with defaults for all parameters' do
    it { should contain_class('puppet_master') }
  end
end
