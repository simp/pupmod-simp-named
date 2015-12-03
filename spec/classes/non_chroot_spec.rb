require 'spec_helper'

describe 'named::non_chroot' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        describe "when selinux_enforced == true" do
          let(:facts){ facts.merge({ :selinux_enforced => true })}

          it { is_expected.to create_class('named::non_chroot') }
          it { is_expected.to contain_package('bind-chroot').with_ensure('absent') }
          it { is_expected.to create_file('/var/named').with_ensure('directory') }
          it { is_expected.to create_file('/etc/named.conf').with_ensure('present') }
        end

        describe "when selinux_enforced == false" do
          let(:facts){ facts.merge({ :selinux_enforced => false })}
          it { is_expected.to raise_error(Puppet::Error, /named::non_chroot must be used with selinux!/) }
        end
      end
    end
  end
end
