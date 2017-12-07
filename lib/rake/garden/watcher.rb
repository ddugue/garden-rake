require 'find'
require 'rb-inotify'
$excluded_directories ||= Set.new [".git", "node_modules", "var", "__pycache__"]

### TODO: Give a way to access accessed events
###       For parallel
module Rake::Garden
  ##
  # Registry to hold reference in a directory tree between parent and sub-folders
  # This way if a folder contains a whole nested structure, you can easily reference
  # the parent node with a child node references without going through a whole
  # directory tree
  ##
  class FolderTree
    include Singleton
    def initialize()
      @folders = Hash.new { |h, k| h[k] = Set.new } # Child folder -> Parent folders
      @hooks = Hash.new { |h, k| h[k] = Set.new }   # Parent folder -> Child folders
      @exclude = $excluded_directories
    end

    ##
    # Recursively find sub-folders of 'folder' and create a dependency link
    # betweene all those sub-folders and this 'folder' in order to raise
    # bubbling events or other type of access
    ##
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
    # Return the previously hooked parents folder of this file
    ##
    def parents(file)
      @folders[File.dirname(file)]
    end

  end

  ##
  # Represent a watch that filters the tree of event result
  # to match only the one pertaining to the desired events
  ##
  class Watch
    def initialize access_watch, modify_watch = nil
      @access_watch = access_watch # Folders to watch for :accessed events
      @modify_watch = modify_watch || access_watch # Folders to watch for :modified events

      @accessed_events = Set.new # Events with :accessed properties
      @modified_events = Set.new # Events with :modified properties
      @new_folders = Set.new # Events that created a new folder
    end

    ##
    # Return all the folders that will need to be watched
    ##
    def folders
      @access_watch + @modify_watch
    end

    ##
    # Return array of accessed events
    ##
    def accessed
      @accessed_events.to_a
    end

    ##
    # Return array of accessed events
    ##
    def outputs
      @modified_events.to_a
    end

    ##
    # Receive all events that happened and filter them to update
    # itself
    ##
    def update events
      @accessed_events = @access_watch.reduce(Set.new) { |set, folder| events[folder][:accessed] + set}
      @modified_events = @modify_watch.reduce(Set.new) { |set, folder| events[folder][:modified] + set}
      @new_folders = @modify_watch.reduce(Set.new) { |set, folder| events[folder][:folder] + set}
      @new_folders.each do |f|
        new_files = Dir.glob("#{f}/**/*")
        @modified_events |= new_files.to_set
      end
      self
    end
  end

  ##
  # Registry for all INotify watchers
  # We can only have ONE inotify watcher per folder
  # so we need to reuse the reference of the inotify watcher globally
  # Since creation of inotify watcher is kinda expensive, we only create them once
  ##
  class Watcher
    include Singleton
    def initialize
      @folder_tree = FolderTree.instance

      @notifier = INotify::Notifier.new

      @events = Hash.new { |h, k| h[k] = {:accessed => Set.new, :modified => Set.new, :folder => Set.new}}
      @watchers = Set.new # Ref of the watched paths
    end

    ##
    # Adds an Inotify watcher on a path and all its sub folder
    ##
    def watch(path)
      # Crawl folder tree
      paths = @folder_tree.hook path

      # Append watcher so we can keep track of active watchers
      paths.each do |path|
        next if @watchers.include? path
        @watchers.add path

        # Append watch to notifier
        @notifier.watch(path, :access, :create, :modify) do |event|
          if !File.directory? event.absolute_name
            if event.flags.include? :access
              @folder_tree.parents(event.absolute_name).each do |glob|
                @events[glob][:accessed].add(event.absolute_name)
              end
            else
              @folder_tree.parents(event.absolute_name).each do |glob|
                @events[glob][:modified].add(event.absolute_name)
              end
            end
          else
            if event.flags.include? :create
              # New directory we add a watch
              @folder_tree.parents(event.absolute_name).each do |glob|
                @events[glob][:folder].add(event.absolute_name)
              end
            end
          end
        end
      end
    end

    ##
    # Process INotify events.
    # If there is no event, do nothing and continue
    ##
    def process()
      while IO.select([@notifier.to_io], [], [], 0)
        @notifier.process
      end
    end

    ##
    # Purge events that can have been registered by anything before an execution
    # Since, we are not closing the INotify file descriptor, any events
    # are queued, even the ones not coming from this execution context
    ##
    def purge(folders)
      @process
      folders.each do |folder|
        @events[folder][:accessed].clear
        @events[folder][:modified].clear
      end
    end

    ##
    # Execute a block then decorates the watch_ins with the events raised by inotify
    ##
    def with(watch_ins, &block)
      # Clean up and watch all folders
      purge watch_ins.folders
      watch_ins.folders.each do |p|; watch p; end

      block.call
      process

      watch_ins.update(@events)
    end

    ##
    # Close the INotify file descriptors
    ##
    def close()
      @notifier.close
    end
  end
end
