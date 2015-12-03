require 'spec_helper'

describe 'named' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        it { is_expected.to create_class('named') }
        it { is_expected.to contain_class('named::chroot') }
        it { is_expected.to contain_package('bind').with_ensure('latest') }
        it { is_expected.to contain_package('bind-libs').with_ensure('latest') }
        it { is_expected.to contain_service('named').with_ensure('running') }
      end
    end
  end
end
