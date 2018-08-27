require "rake/task.rb"
require "ostruct"
require 'time'
require 'set'
require 'json'
require 'pathname'
require 'colorize'
# require "rbtrace"

# TODO:
## Create Cmd for mv, mkdir
## Think about a way to add flags to build rake cmd
## Think about the cd && and the set && IMPOSSIBLE
## Add files command to proxy FileSet
## Think about a :ignore flag for command to allow failure
## Move ShArgs to command subclass
## Create a sync command to make command go in sync
## Create a strace command
module Rake::Garden
  ##
  # A chore is a task you do not want to execute or the execute it as needed
  # It tries to evaluate wether it should be executed or net
  class BaseChore < Rake::Task

    attr_reader :last_executed
    attr_reader :output_files

    def initialize(task_name, app)
      @output_files = FileSet.new
      @metadata = metadata().namespace(task_name)
      @last_executed = Time.at(@metadata.fetch('last_executed', 0) || 0)
      @logger = Logger.new(level:Logger::DEBUG)
      @force = false # Wether to force the task to execute
      super
    end

    ##
    # Return the set of all prequisite files
    ##
    def files(dir=nil)
      return FileSet.new(Dir.glob(dir)) unless dir.nil?

      @files ||=
        begin
          files = FileSet.new
          prerequisite_tasks.select{|t| t.is_a? BaseChore }.each do |t|
            files.merge(t.output_files)
          end
          files
        end
    end

    ##
    # Override execute to decorate the contex with self instance method
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
    end

    ##
    # Since we are not executing with the normal context, [1] will try the command [] which does not exist
    def [](index)
      Array.new([index])
    end

    ##
    # Return wether a single file changed in regard to this task
    ##
    def has_changed(file)
      File.mtime(file) > @last_executed
    end

    def invoke_with_call_chain(*args)
      @succeeded = true
      super
      @logger.flush
      @metadata["last_executed"] = Time.now().to_i if @succeeded and needed?
      exit(1) if !@succeeded
    end

    ##
    # Override
    # Return wether the task need to be override
    def needed?
      needed = prerequisite_tasks.empty? || @force
      needed ||= prerequisite_tasks.any? { |t|
        !t.is_a? BaseChore or t.output_files.any? {|f| has_changed(f) }
      }
      @logger.important(" Skipping task: #{name.capitalize.bold}") if !needed
      needed
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

  module CommandExecutor

    attr_accessor :workdir # Actual work directory of the chore
    attr_accessor :env     # Environment variable passed to commands

    def initialize(task_name, app)
      @queue = []
      @workdir = Pathname.new(Pathname.pwd)
      @env = {}
      @command_index = 0 # Reference for command execution, see queue
      super
    end

    ##
    # Queue command for execution
    def queue(command)
      command.workdir = @workdir
      command.env = @env.clone
      @logger.debug("#{@logger.render_index @command_index} Queuing '#{command.to_s}'")
      @queue << command
      command
    end

    ##
    # Echo a simple message in the async context
    def echo *args
      queue EchoCommand.new(*args)
    end
    ##
    # Set variable environment
    # Can be used like set :VAR => value or set :VAR, value or set VAR:value
    def set(*args)
      queue SetCommand.new(self, *args)
    end

    ##
    # Unset an environment variable
    def unset(var)
      queue UnsetCommand.new(self, var)
    end

    ##
    # Change directory
    def cd(dir)
      queue ChangedirectoryCommand.new(self, dir)
    end

    ##
    # Copy file -> location
    def cp(f, name)
      queue CopyCommand.new(f, name)
    end

    def check(cmd)
      puts "Check: input (#{cmd.input}), command (#{cmd.command}), output (#{cmd.output})"
      puts cmd.to_s
    end

    ##
    # Run a shell command
    def sh(cmd)
      queue ShCommand.new(cmd)
    end
  end

  ##
  # Chore that decorate
  ##
  class Chore < BaseChore
    include CommandExecutor

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        @force = true
      elsif prerequisite_name.instance_of? String and prerequisite_name.include? "."
        return FileChore.new(prerequisite_name, @application)
      else
        return super prerequisite_name.to_s
      end
    end

    def initialize(task_name, app)
      @skipped = 0
      super
    end

    ##
    # Wait for all task to complete
    def wait
      completed = false
      until completed  do
        completed = true
        for cmd in @queue do
          completed = !cmd.wait.nil? & completed
        end
        sleep(0.0001)
      end
    end

    def run
      @queue.each_with_index do |item, index|
        item.run(index)
      end
    end

    def execute(args=nil)
      @logger.info " "
      @logger.important " Running Task: " + name.capitalize.bold
      start = Time.now
      super args

      # Once the queue is filled we execute all the waiting commands
      run and wait

      @skipped =   @queue.count { |cmd| cmd.skip? }
      @succeeded = !@queue.any? { |cmd| cmd.error? }

      @queue.each { |cmd| cmd.log(@logger)}

      @output_files = @queue \
                        .map { |cmd| cmd.output_files } \
                        .reject { |cmd| cmd.nil? } \
                        .reduce(FileSet.new, :+)

      @logger.info(@logger.line(char:"="))
      result = " Result for #{name.capitalize.bold}: "
      result += "Success? #{@succeeded ? "Yes".green : "No".red}, "
      result += "Skipped: #{@skipped.to_s.yellow}, "
      result += "Total user time: #{@logger.render_time(Time.now - start).blue}, "
      result += "Changed files: #{output_files.length.to_s.bold}"
      @logger.important(result)
      @logger.info(" ")
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def needed?
       return (has_changed(@application.rakefile) or super)
    end


    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end
end
