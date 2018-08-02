$DEBUG ||= ENV.fetch("DEBUG", "false") == "true"
# $METADATA ||= ENV.fetch("METADATA", $DEBUG ? ".garden.json" : ".garden")

$METADATA ||= '.garden.json'

require 'rake'
require_relative './garden/hooks.rb'
require_relative './garden/chores.rb'
require_relative './garden/strace.rb'
require_relative './garden/files.rb'
# require_relative './garden/logger.rb'
# require_relative './garden/metadata.rb'
# require_relative './garden/watcher.rb'
# require_relative './garden/execute.rb'
# require_relative './garden/parallel.rb'
class Proc
  def call_with_vars(vars, *args)
    Struct.new(*vars.keys).new(*vars.values).instance_exec(*args, &self)
  end
end

module Rake::Garden
  def metadata()
    $metadata ||= JSONMetadata.new ".garden.json"
  end

  def chore(*args, &block) # :doc:
    Chore.define_task(*args, &block)
  end

  # def open_metadata()
  #   $metadata ||= $METADATA.end_with?(".json") ? JSONMetadata.new($METADATA) : MSGPackMetadata.new($METADATA)
  # end

  # def close_metadata()
  #   if !$metadata.nil?
  #     $metadata.close()
  #   end
  # end

  # def close_threads()
  #   Parallel.instance.stop
  # end

  # def parallel(&block)
  #   open_metadata
  #   Parallel.instance.with($metadata, &block)
  # end


  # # Shortcut functions
  # def execute(command)
  #   open_metadata
  #   if ($in_parallel)
  #     exec = ParallelExecutor.new(command, $metadata)
  #   else
  #     exec = Executor.new(command, $metadata)
  #   end
  #   exec.execute()
  # end


  at_exit {
    $metadata.save if $metadata
  }
  # open_metadata()
end
