require "rake/task.rb"
require "ostruct"
require 'time'
require 'set'
require 'json'
# require "rbtrace"
module Rake::Garden

  class TreeDict
    def initialize(data=nil, parent=nil)
      @data = data || Hash.new
      @parent = parent
      @namespaces = Hash.new
    end

    def namespace(name)
      return @namespaces[name.to_s] if @namespaces.key? name.to_s
      if @data.key? name.to_s
        @namespaces[name.to_s] = TreeDict.new(@data[name.to_s], self)
      else
        @namespaces[nameto_s] = TreeDict.new(nil, self)
      end
    end

    ##
    # Return a single hash data tree
    ##
    def to_json(*)
      @data.merge(@namespaces).to_json()
    end

    def save
      @parent.save if @parent
    end

    def [](ind); @data[ind]; end
    def []=(ind, value); @data[ind] = value; end
    def key?(key); @data.key? key; end
    def fetch(value, default); @data.fetch(value, default); end
  end

  class JSONMetadata < TreeDict
    def initialize(filename)
      @filename = filename
      d = JSON.load(File.read(@filename)) if File.file?(@filename)
      super d
    end

    def save()
      File.open @filename, "w+" do |file|
        JSON.dump(self, file)
      end
    end
  end

  class Chore < Rake::Task
    def initialize(task_name, app)
      @files = nil
      @metadata = metadata().namespace(task_name)
      @last_executed = Time.at(@metadata.fetch('last_executed', 0))
      super task_name, app
    end

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        return NoopChore.new('noop', @application)
      elsif prerequisite_name.instance_of? String and prerequisite_name.include? "."
        return FileChore.new(prerequisite_name, @application)
      else
        return super prerequisite_name.to_s
      end
    end

    def invoke_with_call_chain(*args)
      puts "Overriding in chore"
      super
    end

    ##
    # Return the set of all prequisite files
    ##
    def files
      @files ||=
        begin
          files = Set.new
          prerequisite_tasks.each do |t|
            files.merge(t.dep_files) if t.respond_to? "dep_files"
          end
          files
        end
    end

    ##
    # Return the set of all changed files
    ##
    def dep_files
      return Set.new
    end

    def execute(args=nil)
      args ||= EMPTY_TASK_ARGS
      if application.options.dryrun
        application.trace "** Execute (dry run) #{name}"
        return
      end
      application.trace "** Execute #{name}" if application.options.trace
      application.enhance_with_matching_rule(name) if @actions.empty?
      @actions.each { |act| self.instance_exec(self, args, &act) }
      @metadata["last_executed"] = Time.now().to_i
    end

    # prerequisite_tasks
    def needed?
      needed = prerequisite_tasks.empty?
      prerequisite_tasks.each do |t|
        puts "Checking if #{t} has changed"
        if t.respond_to? "changed?"
          needed ||= t.changed? @last_executed
        else
          puts "#{t} is not responding to changed?"
          needed ||= true
        end
        return needed if needed
      end
      puts "Skipping" if !needed
      needed
    end

    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end

  ##
  # NoopChore
  # NoopChore is a task that does nothing, but will always be resolved to true
  # for changed. Forcing dependant tasks to execute.
  ##
  class NoopChore < Chore

    # Changed? always return true for noop
    def changed?(date=nil)
      true
    end
  end

  ##
  # FileChore
  # FileChore is a task that encapsulate files, it is used to know if a task should
  # execute
  ##
  class FileChore < Chore
    def initialize(task_name, app)
      @pattern = task_name
      super task_name, app
    end

    def files
      @files ||= Set.new(Dir.glob(@pattern))
    end

    # Changed? returns wether the file was modified after date
    def changed?(date=nil)
      !files.find_index { |f| File.mtime(f) > date }.nil?
    end

    # Return all the files the depending chores should treat
    def dep_files
      files
    end
  end
end
