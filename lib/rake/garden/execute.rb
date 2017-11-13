DEBUG = ENV.fetch("DEBUG", "false") == "true"
$excluded_directories ||= Set.new [".git", "node_modules"]

module Rake::Garden
  require 'find'
  class FolderTree
    include Singleton
    def initialize()
      @folders = Hash.new { |h, k| h[k] = Set.new }
      @exclude = $excluded_directories
      @hooks = Hash.new { |h, k| h[k] = Set.new }
    end

    def hook(folder)
      if !@hooks.include? folder
        # We use find to easily exclude some folders
        Find.find(folder) do |path|
          next unless File.directory? path
          if @exclude.include? File.basename(path)
            Find.prune
            next
          end
          abs_path = File.expand_path(folder, path)
          @folders[abs_path].add(folder)
          @hooks[folder].add(abs_path)
        end
      end
      return @hooks[folder]
    end

    ##
    # Return the hooked parents folder of this file
    def parents(file)
      @folders[File.dirname(file)]
    end

  end

  class Watcher
    include Singleton
    def initialize
      @folder_tree = FolderTree.instance

      @notifier = INotify::Notifier.new

      @glob_events = Hash.new { |h, k| h[k] = {:accessed => Set.new, :modified => Set.new}}
      @watchers = Set.new
    end

    def add_watcher(path)
      # Crawl folder tree
      paths = @folder_tree.hook path

      # Append watcher so we can keep track of active watchers
      paths.each do |path|
        next if @watchers.include? path
        @watchers.add path

        # Append watch to notifier
        @notifier.watch(path, :access, :create, :modify) do |event|
          if event.flags.include? :access
            if !File.directory? event.absolute_name
              @folder_tree.parents(event.absolute_name).each do |glob|
                @glob_events[glob][:accessed].add(event.absolute_name)
              end
            end
          else
            @folder_tree.parents(event.absolute_name).each do |glob|
              @glob_events[glob][:modified].add(event.absolute_name)
            end
          end
        end
      end
    end

    def execute(cmd, accessed_folders, modified_folders)
      #We add watcher and clean up old events
      logger = Logger.new
      accessed_folders.each do |folder|
        add_watcher folder
        @glob_events[folder][:accessed].clear
      end

      modified_folders.each do |folder|
        add_watcher folder
        @glob_events[folder][:modified].clear
      end

      if IO.select([@notifier.to_io], [], [], 0)
        @notifier.process
      end

      system cmd

      if IO.select([@notifier.to_io], [], [], 0)
        @notifier.process
      end

      accessed_result = accessed_folders.reduce(Set.new) { |set, folder| @glob_events[folder][:accessed] + set}
      modified_result = modified_folders.reduce(Set.new) { |set, folder| @glob_events[folder][:modified] + set}
      return {
        :accessed => accessed_result,
        :modified => modified_result
      }
    end

    def close()
      @notifier.close
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

    def execute()
      logger = Logger.new

      return logger.log "Skipped #{@command}" if !execute?

      dependencies = Set.new
      outputs = Set.new
      data = @watcher.execute @command, ["."], ["."]
      @metadata[@command] = @metadata.fetch(@command, Hash.new)
      @metadata[@command]["dependencies"] = data[:accessed].to_a
      @metadata[@command]["outputs"] = data[:modified].to_a

      return logger.log "Executed #{@command}"
    end
  end

  at_exit { Watcher.instance.close() }
end
