require 'rake/garden/command_args'

RSpec.describe CommandArgs, "#initialize" do
  it "should create an arg based on a string" do
    expect("a" >> "b").to eq(CommandArgs.new("a", "b"))
  end
  it "should create an arg based on multiple strings" do
    expect("a" >> "b" >> "c").to eq(CommandArgs.new("a", "b", "c"))
  end
  it "should create an arg with arrays" do
    expect(["a", "d"] >> "b" >> "c").to eq(CommandArgs.new(["a", "d"], "b", "c"))
  end
end
