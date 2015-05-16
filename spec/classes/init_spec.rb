require 'spec_helper'

describe 'named' do

  let(:facts) {{
    :operatingsystem   => 'RedHat',
    :lsbmajdistrelease => '6',
    :selinux_enfored => false
  }}

  it { should create_class('named') }
  it { should contain_class('named::chroot') }
  it { should contain_package('bind').with_ensure('latest') }
  it { should contain_package('bind-libs').with_ensure('latest') }
  it { should contain_service('named').with_ensure('running') }
end
