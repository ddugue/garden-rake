require 'rake/garden/commands/cp'
require 'rake/garden/filepath'
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

RSpec.describe Garden::CopyCommand, "processing" do
  before :each do
    %x( rm -fr /tmp/cptest )
    %x( mkdir /tmp/cptest )
    %x( touch /tmp/cptest/a.txt )
  end

  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    cmd = Garden::CopyCommand.new "/tmp/cptest/a.txt", "/tmp/cptest/b.txt"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end
  it "should be able to process a simple command simply" do
    manager = FakeManager.new
    sleep 0.01
    %x( touch /tmp/cptest/b.txt )
    cmd = Garden::CopyCommand.new "/tmp/cptest/a.txt", "/tmp/cptest/b.txt"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.skipped?).to be(true)
    expect(cmd.succeeded?).to be(false)
  end

  it "should be able to use a filepath" do
    manager = FakeManager.new
    cmd = Garden::CopyCommand.new Garden::Filepath.new("/tmp/cptest/a.txt"), "/tmp/cptest/b.txt"
    cmd.manager = manager
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end
end
