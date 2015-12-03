require 'spec_helper'

describe 'named::chroot' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }
        it { is_expected.to create_class('named::chroot') }
        it { is_expected.to contain_package('bind-chroot') }
        it { is_expected.to create_file('/var/named/chroot').with_ensure('directory') }
        it { is_expected.to create_file('/var/named/chroot/etc/named.conf').with_ensure('present') }
        it { is_expected.to create_file('/var/named/chroot/var/named').with_ensure('directory') }
      end
    end
  end
end
