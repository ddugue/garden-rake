require 'rake/garden/command_args'
require 'rake/garden/commands/sh'
require 'rake/garden/context'
require 'rake/garden/filepath'

RSpec.describe Garden::CommandArgs, "#initialize" do
  it "should create an arg based on a string" do
    expect("a" >> "b").to eq(["a", "b"])
  end
  it "should create an arg based on multiple strings" do
    expect("a" >> "b" >> "c").to eq(["a", "b", "c"])
  end
  it "should create an arg with arrays" do
    expect(["a", "d"] >> "b" >> "c").to eq([["a", "d"], "b", "c"])
  end
  it "should create an arg with arrays" do
    expect(["a", "d"] >> ["b", "c"] >> "d").to eq([["a", "d"], ["b", "c"], 'd'])
  end
  it "Should work with a filepath" do
    expect(Garden::Filepath.new("c") >> "b").to eq(["c", 'b'])
  end
end

RSpec.describe Garden::ShArgs do
  context "with all args" do
    subject { Garden::ShArgs.new(nil, ["a.txt", "%b.txt"], "cmd %f", ["c.txt"]) }
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

RSpec.describe Garden::ShCommand do
  context 'with arguments' do
    subject { Garden::ShCommand.new(*args) }

    describe 'with only command' do
      let(:args) { 'cmd' }
      it { is_expected.to have_attributes('command' => 'cmd') }
    end

    describe 'with input and command' do
      let(:args) { 'input.txt' >> 'cmd' }
      it { is_expected.to have_attributes('command' => 'cmd') }
      it "should have rigth input" do
        expect(subject.instance_variable_get(:@args).input).to eq('input.txt')
      end
    end

    describe 'with input and command and output' do
      let(:args) { 'input.txt' >> 'cmd' >> 'output.txt' }
      it { is_expected.to have_attributes('command' => 'cmd') }
      it "should have rigth input" do
        expect(subject.instance_variable_get(:@args).input).to eq('input.txt')
        expect(subject.instance_variable_get(:@args).output).to eq('output.txt')
      end
    end
    describe 'with inputs, output and command' do
      let(:args) { ['input.txt', 'input2.txt'] >> 'cmd' >> 'output.txt' }
      it { is_expected.to have_attributes('command' => 'cmd') }
      it "should have rigth input" do
        expect(subject.instance_variable_get(:@args).input).to eq(['input.txt', 'input2.txt'])
        expect(subject.instance_variable_get(:@args).output).to eq('output.txt')
      end
    end
  end

end
