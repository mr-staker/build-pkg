# frozen_string_literal: true

require 'open3'

require_relative 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe 'staker-repo' do
  describe package('staker-repo') do
    it { should be_installed }
  end

  # this pkg comes from the repo itself with the repo pkg
  # injected by the test installer
  describe package('elrond-test') do
    it { should be_installed }
  end

  describe command('/opt/elrond/bin/node -v') do
    its(:stdout) { should match(/Elrond Node CLI App/) }
    its(:exit_status) { should eq 0 }
  end

  # rpm imports keys from disk from the repo definition
  # apt uses a custom keyring - hence needs to be tested properly
  if File.exist?('/usr/share/keyrings/staker-keyring.gpg')
    keyring = 'gpg --no-default-keyring '\
              '--keyring /usr/share/keyrings/staker-keyring.gpg --list-keys'

    key_info = {}
    keys = Dir["#{File.dirname(__dir__)}/rootfs/**/*.gpg.pem"]
    keys.each do |key|
      out, status = Open3.capture2("gpg --show-keys #{key}")

      raise 'Error: invoking gpg returns failure' unless status.success?

      year = File.basename(key)[-12..-9]
      out = out.split("\n")

      key_info[year] = {
        expire: out[0][-11..-2],
        id: out[1].strip
      }
    end

    describe command(keyring) do
      key_info.each do |_year, info|
        its(:stdout) { should match(info[:id]) }
        its(:stdout) { should match(info[:expire]) }
      end

      its(:exit_status) { should eq 0 }
    end
  end
end
# rubocop:enable Metrics/BlockLength
