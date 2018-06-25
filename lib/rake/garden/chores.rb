require "rake/task.rb"
require "ostruct"
require 'date'
require 'set'
# require "rbtrace"
module Rake::Garden
  class Chore < Rake::Task
    def initialize(task_name, app)
      @last_modified = nil
      @files = nil
      super task_name, app
    end

    ##
    # last_executed return the last time this task was executed
    ##
    def last_executed
      return @last_modified if @last_modified
      return DateTime.new() # Oldest date possible
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
      puts "Skipping #{t}" if !needed
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
      !files.find_index { |f| File.mtime(File.read(f)) > date }.nil?
    end

    # Return all the files the depending chores should treat
    def dep_files
      files
    end
  end
end
