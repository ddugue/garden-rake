require 'rake/garden/commands/echo'
require 'rake/garden/async_manager'

require_relative 'fake_manager'

RSpec.describe Garden::EchoCommand, "processing"do
  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    cmd = Garden::EchoCommand.new manager, "msg"
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end
  it "should be able to process a simple command simply" do
    msg = "MESSAGE"
    cmd = Garden::EchoCommand.new FakeManager.new, msg
    expect(cmd.instance_variable_get(:@args).message).to eq(msg)
  end
end
