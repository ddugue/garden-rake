require 'rake/garden/filepath'
require 'rake/garden/context'

RSpec.describe Garden::Filepath do
  describe "dependable implementation" do

    before(:each) do
      %x( mkdir /tmp/filetest )
      %x( touch /tmp/filetest/a.txt )
    end

    after(:each) do
      %x( rm -fr /tmp/filetest )
    end

    subject { Garden::Filepath.new('/tmp/filetest/a.txt') }

    it "should yield self" do
      subject.each do |obj|
        expect(obj).to eq(subject)
      end
    end

    it "should return modification date" do
      expect(subject.mtime).not_to be_nil
    end

    it "should be nil when non existant" do
      %x( rm /tmp/filetest/a.txt )
      expect(subject.mtime).to be_nil
    end
  end

  context "with format" do
    subject { Garden::Filepath.new('/home/test.txt').format(selector) }

    describe "with %f (filename)" do
      let(:selector) { '%f' }
      it { is_expected.to eql('test.txt') }
    end

    describe "with %F (filename without directory)" do
      let(:selector) { '%F' }
      it { is_expected.to eql('test.txt') }
    end

    describe "with %b (filename without extension)" do
      let(:selector) { '%b' }
      it { is_expected.to eql('test') }
    end

    describe "with %B (filename without directory and extension)" do
      let(:selector) { '%B' }
      it { is_expected.to eql('test') }
    end

    describe "with %d (directory)" do
      let(:selector) { '%d' }
      it { is_expected.to eql('/home/') }
    end

    describe "with %D (full directory)" do
      let(:selector) { '%D' }
      it { is_expected.to eql('/home/') }
    end

    describe "with %x (extension)" do
      let(:selector) { '%x' }
      it { is_expected.to eql('.txt') }
    end
    describe "with %p (fullfilename)" do
      let(:selector) { '%p' }
      it { is_expected.to eql('/home/test.txt') }
    end
  end

  context "with format and directory root" do
    subject { Garden::Filepath.new('/home/sub/test.txt', '/home/').format(selector) }

    describe "with %f" do
      let(:selector) { '%f' }
      it { is_expected.to eql('sub/test.txt') }
    end

    describe "with %F (filename without directory)" do
      let(:selector) { '%F' }
      it { is_expected.to eql('test.txt') }
    end

    describe "with %b (filename without extension)" do
      let(:selector) { '%b' }
      it { is_expected.to eql('sub/test') }
    end

    describe "with %b (filename without directory and extension)" do
      let(:selector) { '%B' }
      it { is_expected.to eql('test') }
    end

    describe "with %d (directory)" do
      let(:selector) { '%d' }
      it { is_expected.to eql('sub/') }
    end

    describe "with %D (full directory)" do
      let(:selector) { '%D' }
      it { is_expected.to eql('/home/sub/') }
    end

    describe "with %p (fullfilename)" do
      let(:selector) { '%p' }
      it { is_expected.to eql('/home/sub/test.txt') }
    end
  end
  describe "with the global context" do
    subject { Garden::Context.instance }
    it "should set directory root when in block" do
      expect(subject.directory_root).to be_nil
      Garden::Filepath.new('/home/ddugue/test.txt', '/home/').each do |obj|
        expect(subject.directory_root).not_to be_nil
        expect(subject.directory_root).to eq('/home/')
      end
    end

    it "should unset directory root when in block" do
      expect(subject.directory_root).to be_nil
      Garden::Filepath.new('/home/ddugue/test.txt', '/home/').each do |obj|
      end
      expect(subject.directory_root).to be_nil
    end

    it "should nest because of the filepath creation" do
      Garden::Filepath.new('/home/ddugue/test.txt', '/home/').each do |obj|
        Garden::Filepath.new('/home/ddugue/test.txt').each do |obj|
          expect(obj.directory_root).to eq('/home/')
          expect(subject.directory_root).to eq('/home/')
        end
      end
    end

    it "should override directory_root" do
      Garden::Filepath.new('/home/ddugue/test.txt', '/home/').each do |obj|
        Garden::Filepath.new('/home/ddugue/test.txt', '/home/ddugue/').each do |obj|
          expect(obj.directory_root).to eq('/home/ddugue/')
        end
        expect(obj.directory_root).to eq('/home/')
      end
    end
  end
end
