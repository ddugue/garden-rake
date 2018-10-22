require 'rake/garden/commands/daemon'
require 'rake/garden/filepath'

require_relative 'fake_manager'

RSpec.describe Garden::DaemonCommand, "processing" do

  after :all do
    %x( killall top )
  end
  it "should be able to start a process" do
    manager = FakeManager.new
    cmd = Garden::DaemonCommand.new manager, "top"
    manager.append(cmd)
    cmd.start
    cmd.result
    expect(cmd.succeeded?).to be(true)
  end
end
