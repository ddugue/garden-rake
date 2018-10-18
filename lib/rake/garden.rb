
$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"

require 'rake'
require 'rake/garden/command_chore'
require 'rake/garden/metadata'
require 'rake/garden/options'
require 'rake/garden/env_parser'
require 'rake/garden/strace'
require 'forwardable'

module Garden
  extend Forwardable
  include EnvParser

  def options()
    $options ||= Option.new
  end

  def_delegators :EnvParser, :env

  def chore(*args, &block) # :doc:
    CommandChore.define_task(options.parse, *args, &block)
  end

  at_exit {
    JSONMetadata.metadata.save
  }
end
