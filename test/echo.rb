require 'rake/garden/commands/echo'
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

RSpec.describe Garden::EchoCommand, "processing"do
  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    cmd = Garden::EchoCommand.new "msg"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end
  it "should be able to process a simple command simply" do
    msg = "MESSAGE"
    cmd = Garden::EchoCommand.new msg
    expect(cmd.instance_variable_get(:@message)).to eq(msg)
  end
end
