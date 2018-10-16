require 'rake/garden/fileset'
require 'rake/garden/context'
require 'rake/garden/fileawarestring'

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

  context "with date filtering" do
    it "should set default since date to the lowest possible date by default" do
      fs = Garden::Fileset.new
      expect(fs.instance_variable_get(:@default_since)).to be < Time.at(0)
    end

    it "should be set to global variable when set up" do
      Garden::Context.instance.with_value :default_since, Time.at(1337) do
        fs = Garden::Fileset.new
        expect(fs.instance_variable_get(:@default_since)).to eq(Time.at(1337))
      end
    end

    it "should be overridable" do
      Garden::Context.instance.with_value :default_since, Time.at(1337) do
        fs = Garden::Fileset.new([], Time.at(1338))
        expect(fs.instance_variable_get(:@default_since)).to eq(Time.at(1338))
      end
    end

    it "should filter date" do
      %x( rm /tmp/datetest )
      %x( mkdir /tmp/datetest )
      %x( touch /tmp/datetest/a.txt )
      sleep 0.1
      fs = Garden::Fileset.new(
        [
          Garden::Filepath.new("/tmp/datetest/a.txt"),
          Garden::Filepath.new("/tmp/datetest/b.txt")
        ], Time.now)
      sleep 0.1
      %x( touch /tmp/datetest/b.txt )
      expect(fs.since.to_a).to eq(["/tmp/datetest/b.txt"])
      expect(fs.changed.to_a).to eq(["/tmp/datetest/b.txt"])
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
  end

end

# RSpec.describe Garden::GlobFileset do
#   after(:all) do
#     %x( rm -fr /tmp/globtest )
#   end

#   before(:all) do
#     %x( mkdir /tmp/globtest )
#   end

#   it "should list all files in a folder" do
#     %x( mkdir /tmp/globtest/prefix )
#     %x( touch /tmp/globtest/prefix/a.txt )
#     %x( touch /tmp/globtest/prefix/b.txt )

#     fs = Garden::GlobFileset.new("/tmp/globtest/**/*.txt")
#     expect(fs.to_a).to eq(["/tmp/globtest/prefix/a.txt",
#                            "/tmp/globtest/prefix/b.txt",
#                           ])
#     fs = Garden::GlobFileset.new("/tmp/**/prefix/*.txt")
#     expect(fs.to_a).to eq(["/tmp/globtest/prefix/a.txt",
#                            "/tmp/globtest/prefix/b.txt",
#                           ])
#   end

#   it "should identify the non-glob part as the root" do
#     fs = Garden::GlobFileset.new("/tmp/globtest/**/*.txt")
#     expect(fs.instance_variable_get(:@directory_root)).to eq("/tmp/globtest/")
#   end

#   it "should substitute the right path" do
#     %x( mkdir /tmp/globtest/prefix )
#     %x( touch /tmp/globtest/prefix/a.txt )
#     %x( touch /tmp/globtest/prefix/b.txt )

#     fs = Garden::GlobFileset.new("/tmp/globtest/**/*.txt")
#     expect(fs.map { Garden::FileAwareString.create("%f").to_s })\
#       .to eq(["prefix/a.txt", "prefix/b.txt"])

#     fs = Garden::GlobFileset.new("/tmp/globtest/**/*.txt")
#     expect(fs.map { Garden::FileAwareString.create("%F").to_s })\
#       .to eq(["a.txt", "b.txt"])
#   end
# end

# RSpec.describe Garden::FilesetGroup do
#   after(:all) do
#     %x( rm -fr /tmp/globtest )
#   end

#   before(:all) do
#     %x( mkdir /tmp/globtest )
#   end

#   before(:each) do
#     %x( mkdir /tmp/globtest/prefix )
#     %x( touch /tmp/globtest/prefix/a.txt )
#     %x( touch /tmp/globtest/prefix/b.txt )
#   end

#   it "should work with a single string" do
#     fg = Garden::FilesetGroup.new("/tmp/globtest/prefix/a.txt")
#     expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt"])
#   end

#   it "should work with an array of strings" do
#     fg = Garden::FilesetGroup.new(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
#     expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
#   end

#   it "should work with a glob" do
#     fg = Garden::FilesetGroup.new("/tmp/globtest/**/*.txt")
#     expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
#   end

#   it "should work with a glob and a string" do
#     fg = Garden::FilesetGroup.new("/tmp/globtest/ddugue", "/tmp/globtest/**/*.txt")
#     expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt", "/tmp/globtest/ddugue"])
#   end

#   it "should work with a fileset and a string" do
#     fg = Garden::FilesetGroup.new(Garden::GlobFileset.new("/tmp/globtest/**/*.txt"), "/tmp/globtest/ddugue")
#     expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt", "/tmp/globtest/ddugue"])
#   end
# end
