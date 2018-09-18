require 'rake/garden/commands/sh'
require 'rake/garden/fileset2'

RSpec.describe Garden::ShCommand, "#arg_parsing"do
  it "should be able to parse a simple command" do
    cmd = Garden::ShCommand.new("input", "cmd", "output")
    expect(cmd.output_files.to_a).to eq(FilesetGroup.new("output").to_a)
  end

  it "should raise an error when trying to parse a wrong data"
end
