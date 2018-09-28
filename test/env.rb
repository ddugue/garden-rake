# frozen_string_literal: true

require 'rake/garden/env_parser'

describe Garden::EnvParser do
  retour = {
    FaKe_DEBUG: 'Yes',
    FaKe_DEBUG_1: 'Y',
    FaKe_DEBUG_2: 'False',
    number: '2',
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

  context 'with booleans' do
    let(:key) { 'FAKE_DEBUG' }
    it { is_expected.to eq(true) }
    describe "Fake_debug_1" do
      let(:key) { 'fake_debug_1' }
      it { is_expected.to eq(true) }
    end
    describe "Fake_debug_2" do
      let(:key) { 'fake_debug_2' }
      it { is_expected.to eq(false) }
    end
  end

  context 'with number' do
      let(:key) { 'number' }
      it { is_expected.to eq(2) }
  end
end
