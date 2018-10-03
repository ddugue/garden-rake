# frozen_string_literal: true

require 'rake/garden/options'

describe Garden::Option do
  let(:args) { [] }
  subject { Garden::Option.new(args) }

  describe 'as an openstruct' do
    it 'should be settable' do
      subject.option_a = 23
      expect(subject.option_a).to eq(23)
    end
  end

  describe 'as an arg parser' do
    let(:args) { ['-b', '3', '--', '--arrival', '3', '--debug', '--prod=2', '--async=false'] }
    before(:each) do
      subject.on('--arrival [NUMBER]', Integer, "Arrival") do |val|
        subject.arrival = val
      end
      subject.on('-b', '--bomba NB', 'Wether it is bombastic') do |val|
        subject.bomba = val
      end
      subject.on('--debug') do |val|
        subject.debug = val
      end
      subject.parse
    end

    it { is_expected.to have_attributes('debug' => true) }
    it { is_expected.to have_attributes('arrival' => 3) }

    it 'should not parse properties before the -- ' do
      expect(subject.bomba).to be nil
    end

    it 'should be possible to add option after initial parsing' do
      subject.on('--async VALUE', TrueClass) do |val|
        subject.async = val
      end
      subject.parse
      expect(subject.async).to be false
    end
  end
end
