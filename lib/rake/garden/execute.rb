
module Rake::Garden
  class Watcher
    include Singleton
    def initialize
      @file_events = Hash.new
      @glob_events = Hash.new

      @thread = nil
      @notifier = INotify::Notifier.new
    end

    def watch(glob, type)
      # We make sure that this glob pattern is registered in the event observers
      @glob_events[glob] = @glob_events.fetch(glob, Hash.new)
      @glob_events[glob][type] = Set.new

      folders = Dir.glob(glob).select { |fn| File.directory?(fn) }
      folders.each do |f|
        if @file_events.key? f
          @file_events[f][type].add(glob)
        else
          @file_events[f] = Hash.new
          @file_events[f][:accessed] = Set.new
          @file_events[f][:modified] = Set.new
          @file_events[f][type].add(glob)
          @notifier.watch(f, :access, :create, :modify, :recursive) do |event|
            if event.flags.include? :access
              @file_events[f][:accessed].each do |glob|
                @glob_events[glob][:accessed].add(event.absolute_name)
              end
            else
              @file_events[f][:modified].each do |glob|
                @glob_events[glob][:modified].add(event.absolute_name)
              end
            end
          end
        end
      end
    end

    def start
      @thread ||= Thread.new do
        @notifier.run
      end
    end

    def pause
      @notifer.stop
    end

    def close
      if !@thread.nil?
        @thread.exit
      end
      @thread = nil
      @notifier.close
    end

    # Return access files
    def accessed(glob)
      @glob_events[glob][:accessed]
    end

    def modified(glob)
      @glob_events[glob][:modified]
    end
  end

  class Executor
    def initialize(command, src_dir=nil, out_dir=nil)
      @metadata = Metadata.instance
      @watcher = Watcher.instance
      @command = command

      @src_dir = src_dir || Dir
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

    def execute()
      logger = Logger.new

      return logger.log "Skipped #{@command}" if !execute?
      @watcher.watch ".", :accessed
      @watcher.watch ".", :modified
      @watcher.start
      system @command

      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = @watcher.accessed(".").to_a
      @metadata[@command]["outputs"] = @watcher.modified(".").to_a

      return logger.log "Executed #{@command}"
    end
  end

  at_exit { Watcher.instance.close() }
end
