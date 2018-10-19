
require 'rake/garden/commands/mkdir'
require 'rake/garden/commands/sh'
require_relative 'fake_manager'

RSpec.describe Garden::MakeDirCommand, "processing" do
  context "only workdir" do
    it "should set the right workdir on manager" do
      %x( rm -fr /tmp/testmakedir )
      manager = FakeManager.new
      cmd = Garden::MakeDirCommand.new "/tmp/testmakedir"
      cmd.manager = manager
      manager.append(cmd)
      cmd.start
      cmd.result
      expect(File.directory? "/tmp/testmakedir").to be(true)
      expect(cmd.succeeded?).to be(true)
    end
  end

end
