require 'rake/garden/fileset'
require 'rake/garden/context'

RSpec.describe Garden::Fileset do
  # subject { Garden::Fileset.new() }

  context "with simple list" do
    before(:each) do
      subject << 'test.txt'
    end
    it "should be transparent to a simple list" do
      subject << "a.txt"
      expect(subject.each.to_a).to eq(["test.txt", "a.txt"])
    end

    it "should be able to iterate over simply" do
      subject.each do |f|
        expect(f).to eq("test.txt")
      end
    end

    it "should be able to filter the fileset by extension" do
      subject << "a.rb"
      expect(subject.ext('txt').to_a).to eq(["test.txt"])
      expect(subject.ext('.txt').to_a).to eq(["test.txt"])
      subject.ext('.txt') do |f|
        expect(f).to eq("test.txt")
      end
    end
  end

  describe "nested content" do
    it "should be nestable" do
      subject << Garden::Fileset.new([Garden::Filepath.new('a.txt')])
      expect(subject.each.to_a).to eq(['a.txt'])
    end
  end

  context "with date filtering" do
    before(:each) do
      subject << "/tmp/datetest/a.txt"
      subject << "/tmp/datetest/b.txt"
      %x( rm -fr /tmp/datetest )
      %x( mkdir /tmp/datetest )
      %x( touch /tmp/datetest/a.txt )
    end

    let! (:time) { sleep 0.1 and Time.now }
    it "should not filter date when not provided" do
      sleep 0.1 and %x( touch /tmp/datetest/b.txt )
      expect(subject.since.to_a).to eq(["/tmp/datetest/a.txt", "/tmp/datetest/b.txt"])
    end

    it "should filter date when directly provided" do
      sleep 0.1 and %x( touch /tmp/datetest/b.txt )
      expect(subject.since(time).to_a).to eq(["/tmp/datetest/b.txt"])
    end

    it "should filter date when indirectly provided" do
      sleep 0.1 and %x( touch /tmp/datetest/b.txt )
      Garden::Context.instance.with_value :default_since, time do
        expect(subject.changed.to_a).to eq(["/tmp/datetest/b.txt"])
      end
    end
  end

  context "with globs" do

    before(:each) do
      %x( mkdir /tmp/globtest )
      %x( mkdir /tmp/globtest/prefix )
      %x( touch /tmp/globtest/prefix/a.txt )
    end

    let(:glob) { "/tmp/globtest/prefix/*.txt" }

    subject { Garden::Fileset.from_glob(glob).to_a }

    after(:each) do
      %x( rm -fr /tmp/globtest )
    end

    it { is_expected.to eq(['/tmp/globtest/prefix/a.txt']) }
    it "should set right directory root" do
      expect(subject[0].directory_root).to eq("/tmp/globtest/prefix/")
    end

    describe "with non glob" do
      let(:glob) { "/tmp/globtest/prefix/a.txt" }
      it { is_expected.to eq(['/tmp/globtest/prefix/a.txt']) }
    end
  end

end
