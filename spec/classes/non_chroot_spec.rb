require 'spec_helper'

describe 'named::non_chroot' do
  let(:facts){{
    :operatingsystem   => 'RedHat',
    :lsbmajdistrelease => '6',
    :selinux_enforced => true
  }}

  it { should create_class('named::non_chroot') }
  it { should contain_package('bind-chroot').with_ensure('absent') }
  it { should create_file('/var/named').with_ensure('directory') }
  it { should create_file('/etc/named.conf').with_ensure('present') }
end
