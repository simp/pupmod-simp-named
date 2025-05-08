require 'spec_helper_acceptance'

test_name 'named chroot'

describe 'named chroot' do
  let(:manifest) do
    <<-EOS
      include 'named::caching'

      named::caching::forwarders { '8.8.8.8': }
    EOS
  end

  hosts.each do |host|
    # Need this for the 'host' command
    host.install_package('bind-utils')

    context 'with internet connection' do
      it 'works with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)

        # verify chrooted service is up and running
        if pfact_on(host, 'init_systems').include?('systemd')
          result = on(host, 'systemctl status named-chroot')
          expect(result.stdout).to match(/active \(running\)/)
          expect(result.stdout).to match(/\/etc\/systemd\/system\/named-chroot.service/)
        else
          on(host, 'service named status')
        end
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is able to lookup www.google.com from itself' do
        on(host, 'echo -e "nameserver 127.0.0.1\nsearch `facter domain`" > /etc/resolv.conf')
        on(host, 'host www.google.com')
      end
    end
  end
end
