require 'rake/garden/fileset'
require 'rake/garden/fileawarestring'

RSpec.describe Garden::Fileset do
  # subject { Garden::Fileset.new() }
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
