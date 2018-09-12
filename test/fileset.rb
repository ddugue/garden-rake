require 'rake/garden/fileset2'
require 'rake/garden/ext/string'

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
    expect(fs.each.map { "prefix/%F".format_with_file! })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])
    expect(fs.map { "prefix/%F".format_with_file! })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])

    fs = Fileset.new()
    fs << "a.txt"
    fs.each do |f|
      expect("%F".format_with_file!).to eq("a.txt")
    end
  end
end

RSpec.describe "File formatting" do
  it "should replace %f with filename + root" do
    expect(format_string_with_file(nil, "/home/test.txt", "%f"))\
      .to eq("test.txt")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%f"))\
      .to eq("sub/test.txt")
  end

  it "should replace %F with only the filename" do
    expect(format_string_with_file(nil, "/home/test.txt", "%F"))\
      .to eq("test.txt")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%F"))\
      .to eq("test.txt")
  end

  it "should replace %b with the filename without extension" do
    expect(format_string_with_file(nil, "/home/test.txt", "%b"))\
      .to eq("test")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%b"))\
      .to eq("sub/test")
  end

  it "should replace %B with only the filename without extension" do
    expect(format_string_with_file(nil, "/home/test.txt", "%B"))\
      .to eq("test")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%B"))\
      .to eq("test")
  end

  it "should replace %x with the extension of the file" do
    expect(format_string_with_file(nil, "/home/test.txt", "%x"))\
      .to eq(".txt")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%x"))\
      .to eq(".txt")
    expect(format_string_with_file("/home/", "/home/sub/test", "%x"))\
      .to eq("")
  end

  it "should replace %d with the directory of the file" do
    expect(format_string_with_file(nil, "/home/test.txt", "%d"))\
      .to eq("/home/")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%d"))\
      .to eq("sub/")
  end

  it "should replace %D with the full directory of the file" do
    expect(format_string_with_file(nil, "/home/test.txt", "%D"))\
      .to eq("/home")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%D"))\
      .to eq("/home/sub")
  end

  it "should replace %p with the full filename" do
    expect(format_string_with_file(nil, "/home/test.txt", "%p"))\
      .to eq("/home/test.txt")
    expect(format_string_with_file("/home/", "/home/sub/test.txt", "%p"))\
      .to eq("/home/sub/test.txt")
  end
end
