require 'rake/garden/fileset2'
require 'rake/garden/filepath'
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
    expect(fs.each.map { FileAwareString.create("prefix/%F").to_s })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])
    expect(fs.map { FileAwareString.create("prefix/%F").to_s })\
      .to eq(["prefix/a.txt", "prefix/test.txt"])

    fs = Fileset.new()
    fs << "a.txt"
    fs.each do |f|
      expect(FileAwareString.create("%f").to_s ).to eq("a.txt")
    end
  end
end
