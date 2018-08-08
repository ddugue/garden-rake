require "rake/task.rb"
require "ostruct"
require 'time'
require 'set'
require 'json'
require 'pathname'
require 'colorize'
# require "rbtrace"
module Rake::Garden

  ##
  # Recursive datastructure to fetch data from a metadata file
  ##
  class TreeDict
    def initialize(data=nil, parent=nil)
      @data = data || Hash.new
      @parent = parent
      @namespaces = Hash.new
    end

    ##
    # Return a sub division of this datastructure
    def namespace(name)
      return @namespaces[name.to_s] if @namespaces.key? name.to_s
      if @data.key? name.to_s
        @namespaces[name.to_s] = TreeDict.new(@data[name.to_s], self)
      else
        @namespaces[name.to_s] = TreeDict.new(nil, self)
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

  ##
  # A chore is a task you do not want to execute or the execute it as needed
  # It tries to evaluate wether it should be executed or net
  class BaseChore < Rake::Task

    attr_reader :last_executed
    attr_reader :output_files

    def initialize(task_name, app)
      @files = nil
      @output_files = FileSet.new
      @metadata = metadata().namespace(task_name)
      @last_executed = Time.at(@metadata.fetch('last_executed', 0))
      super task_name, app
    end

    ##
    # Return the set of all prequisite files
    ##
    def files
      @files ||=
        begin
          files = FileSet.new
          prerequisite_tasks.select{|t| t.is_a? BaseChore }.each do |t|
            files.merge(t.output_files)
          end
          files
        end
    end


    def execute(args=nil)
      args ||= EMPTY_TASK_ARGS
      if application.options.dryrun
        application.trace "** Execute (dry run) #{name}"
        return
      end
      application.trace "** Execute #{name}" if application.options.trace
      application.enhance_with_matching_rule(name) if @actions.empty?

      # Instance exec decorate the context of the lambda with self methods
      @actions.each { |act| self.instance_exec(self, args, &act) }
      @metadata["last_executed"] = Time.now().to_i
    end

    ##
    # Return wether a single file changed in regard to this task
    ##
    def has_changed(file)
      File.mtime(file) > @last_executed
    end

    ##
    # Return wether the task should force is descendant to execute
    ##
    def force?
      false
    end

    def needed?
      needed = prerequisite_tasks.empty? || force?
      prerequisite_tasks.each do |t|
        puts "Checking if #{t} has changed"
        if t.is_a? BaseChore
          needed ||= t.force?
          needed ||= !t.output_files.find_index {|f| has_changed(f) }.nil?
        else
          # We force execution if it is a regular task
          needed ||= true
        end
        return needed if needed
      end
      puts "Skipping #{name}" if !needed
      needed
    end

  end

  ##
  # NoopChore
  # NoopChore is a task that does nothing, but will always be resolved to true
  # for changed. Forcing dependant tasks to execute.
  ##
  class NoopChore < BaseChore
    def force?
      true
    end
  end

  ##
  # FileChore
  # FileChore is a task that encapsulate files, it is used to know if a task should
  # execute
  ##
  class FileChore < BaseChore
    def initialize(task_name, app)
      @pattern = task_name
      super task_name, app
    end

    def needed?
      true
    end

    def output_files
      @files ||= FileSet.new(Dir.glob(@pattern))
    end
  end

  ##
  # AbstractCmd represent an abstract command that can be queued and run
  class AbstractCmd

    # FileSet of input files
    attr_accessor :input_files

    # Fileset of output filse
    attr_accessor :output_files

    def initialize(order, origin, loglevel: nil, workdir: nil, env: nil)
      @order = order
      @origin = origin
      @loglevel = loglevel || nil
      @workdir = workdir || nil
      @env = env || nil
    end

    def log(total)
      "[  ]"
    end
    def debug(msg)
      $stdout.puts msg.grey
    end

    def success(msg)
      $stdout.print
    end


    def execution_time
      @thread.times
    end

    def run
      @stdin, @stdout, @stderr, @thread = Open3.popen3 cmd
    end

    def wait
      @thread.value
    end

    def error?
      @thread.value != 0
    end

    def error
      @stderr.string if @thread.value != 0
    end

    def log
      @stdout.string
    end

    def print
      @stdout.each_line { |line| puts line }
    end

  end


  ##
  # Chore that decorate
  ##
  class Chore < BaseChore
    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        return NoopChore.new('noop', @application)
      elsif prerequisite_name.instance_of? String and prerequisite_name.include? "."
        return FileChore.new(prerequisite_name, @application)
      else
        return super prerequisite_name.to_s
      end
    end

    def initialize(task_name, app)
      @queue = []
      super task_name, app
    end

    def execute(args=nil)
      super args
      # Once the queue is filled we execute all the waiting commands
      @queue.each do |cmd|
        cmd.wait
        cmd.print
      end
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def force?
      has_changed(@application.rakefile)
    end

    def queue(cmd)
      @queue << CmdExecutor.new(cmd)
    end

    def cp(f, name)
      name.magic_format if name.respond_to? :magic_format
      if has_changed(f)
        puts "Queuing cp #{f} #{name}"
        queue "mkdir -p #{Pathname.new(name).dirname} && cp #{f} #{name}"
        @output_files << name
      end
    end

    def sh(cmd)
      puts "Queuing #{cmd}"
      queue cmd
    end

    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end
end
