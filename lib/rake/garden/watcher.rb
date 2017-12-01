require 'find'
require 'rb-inotify'
module Rake::Garden

  ##
  # TODO: Split into a watcher.rb file
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
  # Registry for all INotify watchers
  # We can only have ONE inotify watcher per folder
  # so we need to reuse the reference of the inotify watcher globally
  class Watcher
    include Singleton
    def initialize
      @folder_tree = FolderTree.instance

      @notifier = INotify::Notifier.new

      @events = Hash.new { |h, k| h[k] = {:accessed => Set.new, :modified => Set.new}}
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
    # are cached, even the ones not coming from this execution context
    ##
    def purge(folders)
      @process
      folders.each do |folder|
        @events[folder][:accessed].clear
        @events[folder][:modified].clear
      end
    end

    ## TODO: Split this execute into a block
    ##       so we don't execute the command directly
    # Execute any command and return the modified events
    ##
    def execute(cmd, accessed_folders, modified_folders)
      #We add watcher and clean up old events
      purge accessed_folders
      purge modified_folders

      # Add watchers before executing
      modified_folders.each do |folder|
        watch folder
      end
      accessed_folders.each do |folder|
        watch folder
      end

      # Execution
      result = system cmd
      if !result
        puts "There was an error executing #{cmd}"
        exit 1
      end

      process


      # Combine results
      accessed_result = accessed_folders.reduce(Set.new) { |set, folder| @events[folder][:accessed] + set}
      modified_result = modified_folders.reduce(Set.new) { |set, folder| @events[folder][:modified] + set}
      return {
        :accessed => accessed_result,
        :modified => modified_result
      }
    end

    ##
    # Close the INotify file descriptors
    ##
    def close()
      @notifier.close
    end
  end
end
