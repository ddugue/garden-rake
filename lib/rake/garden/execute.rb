
module Rake::Garden
  require 'find'
  class Watcher
    include Singleton
    def initialize
      @file_events = Hash.new
      @glob_events = Hash.new

      @thread = nil
      @notifier = INotify::Notifier.new
      @mutex = Mutex.new
    end

    def watch(root_folders, type, ignore_directories=nil)
      # We make sure that this glob pattern is registered in the event observers
      ignored_directories = ignore_directories || Set.new
      # TODO: Split in smaller functions

      root_folders.each do |folder|

        @mutex.synchronize do
          @glob_events[folder] = @glob_events.fetch(folder, Hash.new)
          @glob_events[folder][type] = Set.new
        end
        Find.find(folder) do |path|
          if File.directory? path
            if ignored_directories.include? File.basename(path)
              Find.prune
              next
            end

            if @file_events.key? path
              @mutex.synchronize do
                @file_events[path][type].add(folder)
              end
            else
              @mutex.synchronize do
                @file_events[path] = Hash.new
                @file_events[path][:accessed] = Set.new
                @file_events[path][:modified] = Set.new
                @file_events[path][type].add(folder)
              end
              @notifier.watch(path, :access, :create, :modify) do |event|
                if event.flags.include? :access
                    if !File.directory? event.absolute_name
                      puts "Event #{event.absolute_name}"
                      @mutex.synchronize do
                        @file_events[path][:accessed].each do |glob|
                          @glob_events[glob][:accessed].add(event.absolute_name)
                        end
                      end
                    end
                else
                  puts "Event #{event.absolute_name}"
                  @mutex.synchronize do
                    @file_events[path][:modified].each do |glob|
                      @glob_events[glob][:modified].add(event.absolute_name)
                    end
                  end
                end
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
      if !@thread.nil?
        @thread.exit
      end
      @thread = nil
      @notifier.stop
    end

    def close
      if !@thread.nil?
        @thread.exit
      end
      @thread = nil
      @notifier.close
    end

    # Return access files
    def accessed(folders)
      @mutex.synchronize do
        folders.reduce(Set.new) { |set, folder| @glob_events[folder][:accessed] + set }
      end
    end

    def modified(folders)
      @mutex.synchronize do
        folders.reduce(Set.new) { |set, folder| @glob_events[folder][:modified] + set }
      end
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
      @watcher.watch ["."], :accessed, Set.new([".git"])
      @watcher.watch ["."], :modified, Set.new([".git"])
      logger.log "Finished watching"
      @watcher.start

      system @command
      @watcher.pause

      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = @watcher.accessed(["."]).to_a
      @metadata[@command]["outputs"] = @watcher.modified(["."]).to_a

      return logger.log "Executed #{@command}"
    end
  end

  # at_exit { Watcher.instance.close() }
end
