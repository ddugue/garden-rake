require 'rake/garden/filepath'
require 'rake/garden/context'

RSpec.describe Garden::Filepath do
  describe "dependable implementation" do
    subject { Garden::Filepath.new('/home/ddugue/test.txt') }
    it "should yield self" do
      subject.each do |obj|
        expect(obj).to eq(subject)
      end
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
