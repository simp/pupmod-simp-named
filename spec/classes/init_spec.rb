require 'spec_helper'

describe 'named' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        context "with chroot" do
          it { is_expected.to create_class('named') }
          it { is_expected.to contain_class('named::chroot') }
          it { is_expected.to create_file('/var/named/chroot').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf').with_ensure('present') }
          it { is_expected.to create_file('/var/named/chroot/var/named').with_ensure('directory') }
          it { is_expected.to contain_package('bind').with_ensure('latest') }
          it { is_expected.to contain_package('bind-chroot') }
          it { is_expected.to contain_package('bind-libs').with_ensure('latest') }

          if ['RedHat','CentOS'].include? facts[:operatingsystem] and facts[:operatingsystemmajrelease].to_s < '7' then
            it { is_expected.to contain_service('named').with({
              :ensure => 'running',
              :name   => 'named'
            })}
          else
            it { is_expected.to contain_service('named').with({
              :ensure => 'running',
              :name   => 'named-chroot'
            })}
          end
        end
        context "with non-chroot" do
          let(:facts){ facts.merge({ :selinux_enforced => true })}
          it { is_expected.to create_class('named::non_chroot') }
          it { is_expected.to contain_package('bind-chroot').with_ensure('absent') }
          it { is_expected.to create_file('/var/named').with_ensure('directory') }
          it { is_expected.to create_file('/etc/named.conf').with_ensure('present') }

          it { is_expected.to contain_service('named').with({
            :ensure => 'running',
            :name   => 'named'
          })}
        end

        if ['RedHat','CentOS'].include? facts[:operatingsystem] and facts[:operatingsystemmajrelease].to_s >= '7' then
          it { is_expected.to contain_file('/usr/lib/systemd/system/named-chroot.service').with({
            :ensure  => 'present',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
            :content => /.*PIDFile=\/var\/named\/chroot\/run\/named\/named.pid\n*ExecStartPre=\/bin\/bash -c 'if \[ ! "\$DISABLE_ZONE_CHECKING" == "yes" \]; then \/usr\/sbin\/named-checkconf -t \/var\/named\/chroot -z \/etc\/named.conf; else echo "Checking of zone files is disabled"; fi'.*/
          })}
        end
      end
    end
  end
end
