
$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"

require 'rake'
require_relative './garden/chores.rb'
require_relative './garden/commands.rb'
require_relative './garden/logger.rb'
require_relative './garden/strace.rb'
require_relative './garden/files.rb'
require_relative './garden/metadata.rb'

module Rake::Garden
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
