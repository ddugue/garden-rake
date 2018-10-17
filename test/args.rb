require 'rake/garden/command_args'
require 'rake/garden/commands/sh'
require 'rake/garden/context'
require 'rake/garden/filepath'

RSpec.describe Garden::CommandArgs, "#initialize" do
  it "should create an arg based on a string" do
    expect("a" >> "b").to eq(Garden::CommandArgs.new("a", "b"))
  end
  it "should create an arg based on multiple strings" do
    expect("a" >> "b" >> "c").to eq(Garden::CommandArgs.new("a", "b", "c"))
  end
  it "should create an arg with arrays" do
    expect(["a", "d"] >> "b" >> "c").to eq(Garden::CommandArgs.new(["a", "d"], "b", "c"))
  end
end

RSpec.describe Garden::ShArgs do
  context "with all args" do
    subject { Garden::ShArgs.new(["a.txt", "%b.txt"], "cmd %f", ["c.txt"]) }
    it "should work with no context" do
      expect(subject.input).to eq(["a.txt", "%b.txt"])
      expect(subject.command).to eq("cmd %f")
      expect(subject.output).to eq(["c.txt"])
    end

    it "should work with file context" do
      Garden::Context.instance.with_value :file, Garden::Filepath.new("c.rb") do
        expect(subject.command).to eq("cmd c.rb")
        expect(subject.output).to eq(["c.txt"])
        expect(subject.input).to eq(["a.txt", "c.txt"])
      end
    end
  end
end
