require 'spec_helper'

describe 'named::chroot' do
  let(:facts) {{
    :operatingsystem   => 'RedHat',
    :lsbmajdistrelease => '6'
  }}

  it { should create_class('named::chroot') }
  it { should contain_package('bind-chroot') }
  it { should create_file('/var/named/chroot').with_ensure('directory') }
  it { should create_file('/var/named/chroot/etc/named.conf').with_ensure('present') }
  it { should create_file('/var/named/chroot/var/named').with_ensure('directory') }
end
