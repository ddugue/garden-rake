require 'rake/garden/command'
require 'rake/garden/filepath'

RSpec.describe Garden::Command do
  describe "#to_file" do
    subject { Garden::Command.new(nil) }
    it "should convert a string to a filepath" do
      expect(subject.to_file('a.txt')).to be_an(Garden::Filepath)
      expect(subject.to_file('a.txt')).to eq('a.txt')
    end
    it "should convert an array string to an array filepath" do
      expect(subject.to_file(['a.txt']).to_a).to eq(['a.txt'])
    end
    it "should prepend workdir to a string" do
      subject.workdir = 'dav/'
      expect(subject.to_file('a.txt')).to eq('dav/a.txt')
    end
    it "should prepend workdir to an array string" do
      subject.workdir = 'dav/'
      expect(subject.to_file(['a.txt']).to_a).to eq(['dav/a.txt'])
    end
  end
  describe "#to_glob" do
    subject { Garden::Command.new(nil) }

    before(:each) do
      %x( rm -fr /tmp/globtest )
      %x( mkdir /tmp/globtest )
      %x( touch /tmp/globtest/a.txt )
    end

    it "should convert a glob to a fileset" do
      expect(subject.to_glob('/tmp/globtest/*.txt').to_a).to eq(['/tmp/globtest/a.txt'])
      expect(subject.to_glob(['/tmp/globtest/*.txt']).to_a).to eq(['/tmp/globtest/a.txt'])
    end
    it "should prepend workdir to the glob" do
      subject.workdir = '/tmp/globtest/'
      expect(subject.to_glob('*.txt').to_a).to eq(['/tmp/globtest/a.txt'])
      expect(subject.to_glob(['*.txt']).to_a).to eq(['/tmp/globtest/a.txt'])
    end
  end
end
