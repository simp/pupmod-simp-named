require 'spec_helper'

describe 'named::caching' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }
        it { is_expected.to create_class('named::caching') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('bind-chroot') }
        it { is_expected.to create_file('/etc/named.conf') }
        it { is_expected.to create_file('/etc/named.rfc1912.zones') }
        it { is_expected.to contain_service('named').with_ensure('running') }
      end
    end
  end
end
