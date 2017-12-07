
module Rake::Garden

  class Executor
    def initialize(command, metadata, src_dir=nil, out_dir=nil)
      @metadata = metadata
      @watcher = Watcher.instance
      @command = command

      if @command.respond_to? :magic_format
        @command.magic_format() # Replaces some format tags with path info
      end

      @src_dir = src_dir || Dir
      @out_dir = out_dir || Dir
    end

    def time_of_file(f); File.mtime(f).to_i if File.file? f; end

    def execute?()
      results = @metadata.fetch(@command, {"dependencies" => Array.new, "outputs" => Array.new} )
      dep_times = results["dependencies"].map { |x| time_of_file x }.reject { |x| x.nil? }
      out_times = results["outputs"].map { |x| time_of_file x }
      if out_times.any? { |x| x.nil? }
        # We execute if there is a file from the expected outputs that is
        # non-existant
        return true
      elsif dep_times.any? and out_times.any?
        # We execute if one of the dependency is more recent than an output
        return out_times.min < dep_times.max
      end
      # We execute if there is no dependency or no output (default)
      return true
    end

    def execute()
      logger = Logger.new

      return logger.log "Skipped #{@command}" if !execute?

      data = @watcher.with Watch.new ["."] do
        system @command
      end
      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = data.accessed
      @metadata[@command]["outputs"] = data.outputs

      return logger.log "Executed #{@command}"
    end
  end

  ##
  # Executor that executes commands in parallel via the parallel class
  # Incidently, does not check if it changes. This will be the role
  ##
  class ParallelExecutor < Executor
    def execute()
      logger = Logger.new
      return logger.log "Skipped #{@command}" if !execute?

      Parallel.instance.queue @command

      return logger.log "Queued #{@command} for execution"
    end
  end

  at_exit { Watcher.instance.close() }
end
