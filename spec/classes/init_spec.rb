require 'spec_helper'

describe 'named' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        context "with chroot and no selinux" do
          let(:facts){ facts.merge({ :selinux_enforced => false })}

          it { is_expected.to create_class('named') }
          it { is_expected.to contain_class('named::chroot') }
          it { is_expected.to create_file('/var/named/chroot').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf').with_ensure('file') }
          it { is_expected.to create_file('/var/named/chroot/var/named').with_ensure('directory') }
          it { is_expected.to contain_package('bind').with_ensure('latest') }
          it { is_expected.to contain_package('bind-chroot') }
          it { is_expected.to contain_package('bind-libs').with_ensure('latest') }

          if ['RedHat','CentOS'].include? facts[:operatingsystem] and facts[:operatingsystemmajrelease].to_s < '7' then
            it { is_expected.to contain_service('named').with({
              :ensure => 'running'
            })}
          else
            it { is_expected.to contain_service('named-chroot').with({
              :ensure => 'running'
            })}
          end

          it { is_expected.to contain_rsync('named').with({
            :source => "bind_dns_default_#{environment}/named/"
            })
          }
        end

        context "with non-chroot" do
          let(:facts){ facts.merge({ :selinux_enforced => true })}

          it { is_expected.to create_class('named::non_chroot') }
          it { is_expected.to contain_package('bind-chroot').with_ensure('absent') }
          it { is_expected.to create_file('/var/named').with_ensure('directory') }
          it { is_expected.to create_file('/etc/named.conf').with_ensure('file') }

          it { is_expected.to contain_service('named').with({
            :ensure => 'running'
          })}

          it { is_expected.to contain_rsync('named').with({
            :source => "bind_dns_default_#{environment}/named/var/named"
            })
          }
        end

        if ['RedHat','CentOS'].include? facts[:operatingsystem] and facts[:operatingsystemmajrelease].to_s >= '7' then
          it { is_expected.to contain_file('/usr/lib/systemd/system/named-chroot.service').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
            :content => /.*ExecStartPre=\/bin\/bash -c 'if \[ ! "\$DISABLE_ZONE_CHECKING" == "yes" \]; then \/usr\/sbin\/named-checkconf -t \/var\/named\/chroot -z \/etc\/named.conf; else echo "Checking of zone files is disabled"; fi'.*/
          })}
        end

        context 'when trying to include ::named::caching' do
          let(:pre_condition){
            %(include '::named::caching')
          }

          # We should get a resource conflict here.
          it {
            expect {
              is_expected.to compile.with_all_deps
            }.to raise_error(/cannot include both/)
          }
        end
      end
    end
  end
end
