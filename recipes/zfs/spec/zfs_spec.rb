# frozen_string_literal: true

require_relative 'spec_helper'

describe 'zfs' do
  Dir['/build/pkg/*'].each do |pkg|
    describe file(pkg) do
      # this is a hard limit for CF Pages
      its(:size) { should < 26214400 }
    end
  end
end
