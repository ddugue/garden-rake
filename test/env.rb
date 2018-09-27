# frozen_string_literal: true

require 'rake/garden/env_parser'

describe Garden::EnvParser do
  retour = {
    FaKe_DEBUG: 'Yes',
    PRODUCTION: 'node'
  }
  before(:each) do
    allow(ENV).to receive(:to_h).and_return(retour)
  end

  let(:default) { nil }
  subject { Garden::EnvParser.env(key, default: default) }

  context 'with strings' do
    let(:key) { 'PRODUCTION' }
    it { is_expected.to eq('node') }
  end
end
