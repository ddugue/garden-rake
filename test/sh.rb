require 'rake/garden/commands/sh'
require 'rake/garden/async_manager'

require_relative 'fake_manager'


RSpec.describe Garden::ShCommand, "processing"do
  before :each do
    %x( rm -fr /tmp/shtest )
    %x( mkdir /tmp/shtest )
    %x( touch /tmp/shtest/a.txt )
  end

  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    cmd = Garden::ShCommand.new manager, "touch /tmp/shtest/c.txt"
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end

  it "should be able to process an error command gracefully" do
    manager = FakeManager.new
    cmd = Garden::ShCommand.new manager, "rm /tmp/shtest"
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.error?).to be(true)
  end

  it "should be able to skip a command" do
    manager = FakeManager.new
    sleep 0.01
    %x( touch /tmp/shtest/b.txt )
    cmd = Garden::ShCommand.new(manager, "/tmp/shtest/a.txt", "rm /tmp/shtest", "/tmp/shtest/b.txt")
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.skipped?).to be(true)
    expect(cmd.succeeded?).to be(false)
    expect(cmd.error?).to be(false)
  end
end
