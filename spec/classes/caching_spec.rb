require 'spec_helper'

describe 'named::caching' do

  let(:facts) {{
    :operatingsystem   => 'RedHat',
    :lsbmajdistrelease => '6',
    :selinux_enforced  => false
  }}

  it { should create_class('named::caching') }
  it { should compile.with_all_deps }
  it { should contain_package('bind-chroot') }
  it { should create_file('/etc/named.conf') }
  it { should create_file('/etc/named.rfc1912.zones') }
  it { should contain_service('named').with_ensure('running') }
end
