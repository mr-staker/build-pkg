# frozen_string_literal: true

require_relative 'spec_helper'

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
end
