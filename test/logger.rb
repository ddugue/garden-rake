# coding: utf-8
# frozen_string_literal: true

require 'rake/garden/logger'
describe Garden::Logger do
  describe '.truncate' do
    context 'with long sentence' do
      let(:sentence) { subject.class.truncate('this is a longer sentence', 10, '....') }

      it 'should set the right length' do
        expect(sentence.length).to eq(10)
      end
      it 'should end with the suffix' do
        expect(sentence).to end_with '....'
      end
    end

    context 'with short sentence' do
      let(:sentence) { subject.class.truncate('this', 10, '....') }

      it 'should not alter length' do
        expect(sentence.length).to eq(4)
      end
      it 'should not end with suffix' do
        expect(sentence).not_to end_with '....'
      end
    end
  end

  describe '.align' do
    before(:example) do
      allow(subject.class).to receive(:terminal_width).and_return(25)
    end

    context 'without colored strings' do
      let(:aligned) { subject.class.align('PREFIX', 'MIDDLE', 'SUFFIX') }

      it 'should align to size of the terminal' do
        expect(aligned.length).to eq(25)
      end
      it 'should be aligned to the right' do
        expect(aligned).to eq('PREFIXMIDDLE       SUFFIX')
      end
    end

    context 'with colored strings' do
      let(:aligned) { subject.class.align('PREFIX'.blue, 'MIDDLE'.red, 'SUFFIX') }

      it 'should be aligned to the right' do
        expect(aligned).to eq('PREFIX'.blue + 'MIDDLE'.red + '       SUFFIX')
      end
    end
  end

  describe '.hierarchy' do
    let(:result) { '   [2] ' }

    it 'should work with int' do
      expect(subject.class.hierarchy(2)).to eq(result)
    end
    it 'should work with str' do
      expect(subject.class.hierarchy('2')).to eq(result)
    end

    context 'with sub' do
      let(:result) { '    └[2.2] ' }

      it 'should work with float' do
        expect(subject.class.hierarchy(2.2)).to eq(result)
      end
      it 'should work with str' do
        expect(subject.class.hierarchy('2.2')).to eq(result)
      end
    end
  end

  describe '.line' do
    before(:example) do
      allow(subject.class).to receive(:terminal_width).and_return(5)
    end

    let(:line) { subject.class.line }
    it 'should be a single line' do
      expect(line).to eq(' --- ')
    end
    it 'should be the length of the terminal' do
      expect(line.length).to eq(5)
    end
    context 'with custom char' do
      let(:line) { subject.class.line(char: '*') }
      it 'should be a single line of the same char' do
        expect(line).to eq(' *** ')
      end
    end
  end

  describe '.time' do
    context 'with 0 seconds' do
      let(:time) { subject.class.time(0) }
      it 'should be max 6 char' do
        expect(time.length).to be <= 6
      end
    end
    context 'with less than 10 seconds' do
      let(:time) { subject.class.time(9) }
      it 'should be max 6 char' do
        expect(time.length).to be <= 6
      end
    end
    context 'with less than a minute' do
      let(:time) { subject.class.time(59) }
      it 'should be max 6 char' do
        expect(time.length).to be <= 6
      end
    end
    context 'with less than a hour' do
      let(:time) { subject.class.time(60 * 60 - 1) }
      it 'should be max 6 char' do
        expect(time.length).to be <= 6
      end
    end
    context 'with more than a hour' do
      let(:time) { subject.class.time(60 * 60 + 1) }
      it 'should be max 6 char' do
        expect(time.length).to be <= 6
      end
    end
  end

  describe '.pad_for_hierarchy' do
  end
end
