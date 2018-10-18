require 'rake/garden/commands/sh'
require 'rake/garden/async_manager'

class FakeManager
  include Garden::AsyncManager
  def initialize
    @asyncs = []
  end
  def asyncs
    @asyncs
  end
  def append(elem)
    @asyncs.append(elem)
  end
  def wait_for(id)
    completed = false
    until completed
      completed = true
      asyncs.each do |process|
        process.update_status
        completed = process.completed? if id == process.execution_order
      end

      sleep(0.0001)
    end
  end
end

RSpec.describe Garden::ShCommand, "processing"do
  before :each do
    %x( rm -fr /tmp/shtest )
    %x( mkdir /tmp/shtest )
    %x( touch /tmp/shtest/a.txt )
  end

  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    cmd = Garden::ShCommand.new "touch /tmp/shtest/c.txt"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end

  it "should be able to process an error command gracefully" do
    manager = FakeManager.new
    cmd = Garden::ShCommand.new "rm /tmp/shtest"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.error?).to be(true)
  end

  it "should be able to skip a command" do
    manager = FakeManager.new
    sleep 0.01
    %x( touch /tmp/shtest/b.txt )
    cmd = Garden::ShCommand.new("/tmp/shtest/a.txt", "rm /tmp/shtest", "/tmp/shtest/b.txt")
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.skipped?).to be(true)
    expect(cmd.succeeded?).to be(false)
    expect(cmd.error?).to be(false)
  end
end
