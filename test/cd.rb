require 'pathname'

require 'rake/garden/commands/cd'
require 'rake/garden/async_manager'

class FakeManager
  include Garden::AsyncManager
  attr_accessor :workdir
  def initialize
    @asyncs = []
    @workdir = Pathname.new('/')
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

RSpec.describe Garden::ChangedirectoryCommand, "processing" do
  context "only workdir" do
    it "should set the right workdir on manager" do
      manager = FakeManager.new
      cmd = Garden::ChangedirectoryCommand.new "tmp"
      cmd.manager = manager
      cmd.workdir = manager.workdir
      expect(manager.workdir.to_s).to eq('/tmp/')
    end
  end
end
