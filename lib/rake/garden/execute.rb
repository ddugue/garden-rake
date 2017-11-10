
module Rake::Garden

  class Executor
    def initialize(command)
      @metadata = Metadata.instance
      @command = command

      @dependencies = Set.new
      @outputs = Set.new
    end

    def time_of_file(f); File.mtime(f).to_i if File.file? f; end

    def execute?()
      results = @metadata.fetch(@command, {"dependencies" => Array.new, "outputs" => Array.new} )
      dep_times = results["dependencies"].map { |x| time_of_file x }.reject { |x| x.nil? }
      out_times = results["outputs"].map { |x| time_of_file x }
      if out_times.any? { |x| x.nil? }
        return true
      elsif dep_times.any? and out_times.any?
        return out_times.min < dep_times.max
      end
      return true
    end

    # Return directories to watch when calling this task
    def directories()
      [Dir.pwd]
    end

    # Asynchronously watch for files
    def watch
      notifier = INotify::Notifier.new
      thr = Thread.new do
        directories.each do |directory|
          notifier.watch(directory, :access, :create, :modify, :recursive) do |event|
            if event.flags.include? :access
              @dependencies.add event.absolute_name
            else
              @outputs.add event.absolute_name
            end
          end
        end
        notifier.run
      end
      return (lambda do
                thr.exit
                notifier.close
              end)
    end

    def execute()
      logger = Logger.new

      return logger.log "Skipped #{@command}" if !execute?
      close = watch
      system @command
      close.call

      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = @dependencies.to_a
      @metadata[@command]["outputs"] = @outputs.to_a

      return logger.log "Executed #{@command}"
    end
  end
end
