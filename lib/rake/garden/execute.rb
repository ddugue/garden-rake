$excluded_directories ||= Set.new [".git", "node_modules", "var", "__pycache__"]

module Rake::Garden


  ## TODO: Split into multiple Executor class with different execute? methods
  class Executor
    def initialize(command, metadata, src_dir=nil, out_dir=nil)
      @metadata = metadata
      @watcher = Watcher.instance
      @command = command

      if @command.respond_to? :magic_format
        @command.magic_format()
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

      data = @watcher.execute @command, ["."], ["."]
      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = data[:accessed].to_a
      @metadata[@command]["outputs"] = data[:modified].to_a

      return logger.log "Executed #{@command}"
    end
  end

  at_exit { Watcher.instance.close() }
end
