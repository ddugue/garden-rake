$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"
$METADATA ||= ENV.fetch("METADATA", $DEBUG ? ".garden.json" : ".garden")

require 'rake'
require_relative './garden/logger.rb'
require_relative './garden/metadata.rb'
require_relative './garden/watcher.rb'
require_relative './garden/execute.rb'
require_relative './garden/files.rb'
require_relative './garden/parallel.rb'

module Rake::Garden

  def open_metadata()
    $metadata ||= $METADATA.end_with?(".json") ? JSONMetadata.new($METADATA) : MSGPackMetadata.new($METADATA)
  end

  def close_metadata()
    if !$metadata.nil?
      $metadata.close()
    end
  end

  def close_threads()
    Parallel.instance.stop
  end

  def parallel(&block)
    open_metadata
    Parallel.instance.with($metadata, &block)
  end


  # Shortcut functions
  def execute(command)
    open_metadata
    if ($in_parallel)
      exec = ParallelExecutor.new(command, $metadata)
    else
      exec = Executor.new(command, $metadata)
    end
    exec.execute()
  end


  at_exit {
    close_metadata()
    close_threads()
  }
end
