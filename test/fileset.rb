require 'rake/garden/fileset'
require 'rake/garden/fileaware_string'

RSpec.describe Fileset do
  it "should be transparent to a simple list" do
    fs = Fileset.new()
    fs << "test.txt"
    fs << "a.txt"
    expect(fs.each.to_a).to eq(["test.txt", "a.txt"])
  end

  it "should be able to iterate over simply" do
    fs = Fileset.new()
    fs << "test.txt"
    fs.each do |f|
      expect(f).to eq("test.txt")
    end
  end

  it "should do simple path substitution" do
    fs = Fileset.new()
    fs << "a.txt"
    fs << "test.txt"
    expect(fs.each.map { FileAwareString.create("prefix/%F").to_s })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])
    expect(fs.map { FileAwareString.create("prefix/%F").to_s })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])

    fs = Fileset.new()
    fs << "a.txt"
    fs.each do |f|
      expect(FileAwareString["%f"].to_s ).to eq("a.txt")
    end
  end
end

RSpec.describe GlobFileset do
  after(:all) do
    %x( rm -fr /tmp/globtest )
  end

  before(:all) do
    %x( mkdir /tmp/globtest )
  end

  it "should list all files in a folder" do
    %x( mkdir /tmp/globtest/prefix )
    %x( touch /tmp/globtest/prefix/a.txt )
    %x( touch /tmp/globtest/prefix/b.txt )

    fs = GlobFileset.new("/tmp/globtest/**/*.txt")
    expect(fs.to_a).to eq(["/tmp/globtest/prefix/a.txt",
                           "/tmp/globtest/prefix/b.txt",
                          ])
    fs = GlobFileset.new("/tmp/**/prefix/*.txt")
    expect(fs.to_a).to eq(["/tmp/globtest/prefix/a.txt",
                           "/tmp/globtest/prefix/b.txt",
                          ])
  end

  it "should identify the non-glob part as the root" do
    fs = GlobFileset.new("/tmp/globtest/**/*.txt")
    expect(fs.instance_variable_get(:@folder_root)).to eq("/tmp/globtest/")
  end

  it "should substitute the right path" do
    %x( mkdir /tmp/globtest/prefix )
    %x( touch /tmp/globtest/prefix/a.txt )
    %x( touch /tmp/globtest/prefix/b.txt )

    fs = GlobFileset.new("/tmp/globtest/**/*.txt")
    expect(fs.map { FileAwareString.create("%f").to_s })\
      .to eq(["prefix/a.txt", "prefix/b.txt"])

    fs = GlobFileset.new("/tmp/globtest/**/*.txt")
    expect(fs.map { FileAwareString.create("%F").to_s })\
      .to eq(["a.txt", "b.txt"])
  end
end

RSpec.describe FilesetGroup do
  after(:all) do
    %x( rm -fr /tmp/globtest )
  end

  before(:all) do
    %x( mkdir /tmp/globtest )
  end

  before(:each) do
    %x( mkdir /tmp/globtest/prefix )
    %x( touch /tmp/globtest/prefix/a.txt )
    %x( touch /tmp/globtest/prefix/b.txt )
  end

  it "should work with a single string" do
    fg = FilesetGroup.new("/tmp/globtest/prefix/a.txt")
    expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt"])
  end

  it "should work with an array of strings" do
    fg = FilesetGroup.new(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
    expect(fg.to_a).to eq(["/tmp/globtest/prefix/b.txt", "/tmp/globtest/prefix/a.txt"])
  end

  it "should work with a glob" do
    fg = FilesetGroup.new("/tmp/globtest/**/*.txt")
    expect(fg.to_a).to eq(["/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
  end

  it "should work with a glob and a string" do
    fg = FilesetGroup.new("/tmp/globtest/ddugue", "/tmp/globtest/**/*.txt")
    expect(fg.to_a).to eq(["/tmp/globtest/ddugue", "/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
  end

  it "should work with a fileset and a string" do
    fg = FilesetGroup.new(GlobFileset.new("/tmp/globtest/**/*.txt"), "/tmp/globtest/ddugue")
    expect(fg.to_a).to eq(["/tmp/globtest/ddugue", "/tmp/globtest/prefix/a.txt", "/tmp/globtest/prefix/b.txt"])
  end

  it "should create a file aware string" do
    FileAwareString.file = "a.txt"
    fg = FilesetGroup.new("%f")
    expect(fg.to_a).to eq(["a.txt"])
    FileAwareString.file = nil
  end
end
