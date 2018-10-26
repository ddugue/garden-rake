
require 'rake/garden/commands/cd'
require 'rake/garden/commands/sh'
require_relative 'fake_manager'

RSpec.describe "Garden::ChangedirectoryCommand", "processing" do
  context "only workdir" do
    it "should set the right workdir on manager" do
      manager = FakeManager.new
      expect(manager.workdir).not_to be_nil
      cmd = Garden::ChangedirectoryCommand.new manager, "tmp"
      expect(manager.workdir.to_s).to eq('/tmp/')
    end
  end

end
