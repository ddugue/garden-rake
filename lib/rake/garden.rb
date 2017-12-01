$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"
$METADATA ||= ENV.fetch("METADATA", $DEBUG ? ".garden.json" : ".garden")

require 'rake'
require_relative './garden/logger.rb'
require_relative './garden/metadata.rb'
require_relative './garden/watcher.rb'
require_relative './garden/execute.rb'
require_relative './garden/files.rb'

module Rake::Garden

  def open_metadata()
    $metadata ||= $METADATA.end_with?(".json") ? JSONMetadata.new($METADATA) : MSGPackMetadata.new($METADATA)
  end

  def close_metadata()
    if !$metadata.nil?
      $metadata.close()
    end
  end

  # Shortcut functions
  def execute(command)
    open_metadata
    exec = Executor.new(command, $metadata)
    exec.execute()
  end

  at_exit { close_metadata() }
end
