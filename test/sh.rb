require 'rake/garden/commands/sh'
require 'rake/garden/fileset2'

RSpec.describe Garden::ShCommand, "#arg_parsing"do
  it "should be able to parse a simple command" do
    cmd = Garden::ShCommand.new(nil, "input", "cmd", "output")
    expect(cmd.output_files.to_a).to eq(FilesetGroup.new("output").to_a)
  end

  it "should work with empty data" do
    cmd = Garden::ShCommand.new(nil, "input", "cmd", [])
    expect(cmd.output_files.to_a).to eq(FilesetGroup.new().to_a)
  end

  it "should provide default data" do
    cmd = Garden::ShCommand.new(nil, "input", "cmd", [])
    expect(cmd.output_files.to_a).to eq(FilesetGroup.new().to_a)
  end

  it "should raise an error when trying to parse a wrong data" do
    expect { Garden::ShCommand.new(nil, "input", ["cmd"], "output") }.to raise_error(ParsingError)
  end

  it "should raise an error when trying with too much data" do
    expect { Garden::ShCommand.new(nil, "input", ["cmd"], "output", "fourth") }.to raise_error(ParsingError)
  end
end
