
$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"

require 'rake'
require 'rake/garden/chores'
require 'rake/garden/commands'
require 'rake/garden/logger'
require 'rake/garden/strace'
require 'rake/garden/files'
require 'rake/garden/metadata'

module Rake::Garden

  def options()
    $options ||= OpenStruct.new
  end

  def metadata()
    $metadata ||= JSONMetadata.new ".garden.json"
  end

  def chore(*args, &block) # :doc:
    Chore.define_task(*args, &block)
  end

  at_exit {
    $metadata.save if $metadata
  }
end
