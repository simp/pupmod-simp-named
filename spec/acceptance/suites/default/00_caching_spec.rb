require 'spec_helper_acceptance'

test_name 'named::caching'

describe 'named::caching' do
  let(:manifest) do
    <<~EOS
      include 'named::caching'

      named::caching::forwarders { '8.8.8.8': }
    EOS
  end

  hosts.each do |host|
    # Need this for the 'host' command
    host.install_package('bind-utils')

    # Exercise noop from a clean state: on a fresh node the Sicura console
    # previews the module with `puppet apply --noop`, which must not error. This
    # runs before the applies below install/configure bind, so it is the genuine
    # fresh-node preview. A post-convergence noop check is omitted (`--noop
    # --detailed-exitcodes` always exits 0). No package removal (as with
    # fips/ssh): a fresh node has the base `bind-libs` already, so the honest
    # clean state is "installed but not yet SIMP-managed", which is exactly what
    # a bare noop of the module's manifest previews (nothing is resolved over
    # the network under --noop, so no live forwarder is required).
    context 'in noop mode from a clean state' do
      it 'applies without errors in noop mode' do
        apply_manifest_on(host, manifest, catch_failures: true, noop: true)
      end
    end

    context 'with internet connection' do
      it 'works with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_failures: true, cactch_changes: true)
      end

      it 'is able to lookup www.google.com from itself' do
        on(host, 'echo -e "nameserver 127.0.0.1\nsearch `facter domain`" > /etc/resolv.conf')
        on(host, 'host www.google.com')
      end
    end
  end
end
