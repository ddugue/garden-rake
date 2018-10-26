
require 'rake/garden/commands/set'
require 'rake/garden/commands/unset'
require_relative 'fake_manager'

RSpec.describe "Garden::SetCommand", "processing" do
  let(:manager) { FakeManager.new }
  context "only values" do
    it "should set the right env and value on manager with string" do
      cmd = Garden::SetCommand.new manager, "key", "value"
      expect(manager.env["key"]).to eq('value')
    end
    it "should set the right env and value on manager with symbols" do
      cmd = Garden::SetCommand.new manager, :key, "value"
      expect(manager.env["key"]).to eq('value')
    end
  end
  context "with keystore" do
    it "should set the right env and value on manager with dict" do
      cmd = Garden::SetCommand.new manager, "key" => "value"
      expect(manager.env["key"]).to eq('value')
    end
    it "should set the right env and value on manager with key value" do
      cmd = Garden::SetCommand.new manager, key: "value"
      expect(manager.env["key"]).to eq('value')
    end
  end

  context "with unset" do
    it "should set the right env and then remove it" do
      cmd = Garden::SetCommand.new manager, :key, "value"
      expect(manager.env["key"]).to eq('value')
      cmd = Garden::UnsetCommand.new manager, :key
      expect(manager.env.key? "key").to be(false)
    end
  end
end
