require "rake/task.rb"
require "ostruct"
require 'time'
require 'set'
require 'json'
require 'pathname'
require 'colorize'
# require "rbtrace"

# TODO:
## Split files
## Create Cmd for mv, sh!
## Create Cmd for sh
## Think about a way to add flags to build rake cmd
## Cleanup other files
## Think about the cd && and the set &&
## Think about overriding >> for nice effect with sh
## Think about getting output from command
## Add files command to proxy FileSet
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
      @command_index = 0 # Reference for command execution, see queue
      @logger = Logger.new(level:Logger::VERBOSE)
      @force = false # Wether to force the task to execute
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
    end

    ##
    # Return wether a single file changed in regard to this task
    ##
    def has_changed(file)
      File.mtime(file) > @last_executed
    end

    def invoke_with_call_chain(*args)
      @succeeded = true
      super *args
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

  ##
  # Return the first line number found
  def get_line_number
    caller_locations.find { |loc| loc.path.include? 'rakefile' }.lineno
  end

  ##
  # Render a time with max 6 char
  def render_time(time)
    if time < 10
      "#{time.round(3)}s"
    elsif time >= 3600
      "#{(time / 3600).floor}h#{(time % 3600 / 60).floor.to_s.ljust(2, "0")}m"
    elsif time >= 60
      "#{(time / 60).floor}m#{(time % 60).floor}s"
    else
      "#{time.round(2)}s"
    end
  end

  ##
  # Render a single index
  def render_index(nb, nbdigits: 3)
    "[#{nb}]".rjust nbdigits + 3
  end

  ##
  # Crop a long string with ...
  def truncate s, length = 30, ellipsis = '...'
    if s.length > length
      s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
    else
      s
    end
  end


  ##
  # Chore that decorate
  ##
  class Chore < BaseChore
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
      @queue = []
      @skipped = 0
      @workdir = Pathname.new(Pathname.pwd)
      @env = {}
      super task_name, app
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

    def execute(args=nil)
      @logger.info " "
      @logger.important " Running Task: " + name.capitalize.bold
      start = Time.now
      super args

      # Once the queue is filled we execute all the waiting commands
      wait

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
      result += "Total user time: #{render_time(Time.now - start).blue}, "
      result += "Changed files: #{output_files.length.to_s.bold}"
      @logger.important(result)
      @logger.info(" ")
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def needed?
       return (has_changed(@application.rakefile) or super)
    end

    ##
    # Queue command for execution
    def queue(command)
      @command_index += 1
      command.workdir = @workdir
      command.env = @env.clone
      @logger.debug("#{render_index @command_index} Queuing '#{command.to_s}'")
      @queue << command.run(@command_index)
      command
    end

    ##
    # Set variable environment
    # Can be used like set :VAR => value or set :VAR, value or set VAR:value
    def set(*args)
      if args.length > 1
        # first arg is a symbol, second is value
        dict = {args[0].to_s => args[1].to_s}
      elsif args.length == 1
        # first arg is a dict
        raise "Set argument must be an hash" if not args[0].is_a? Hash
        dict = Hash[args[0].map { |k, v| [k.to_s, v.to_s] }]
      else
        raise 'Invalid syntax for set. Please see docs'
      end
      @env.merge! dict
      queue SetCommand.new(dict)
    end

    ##
    # Unset an environment variable
    def unset(var)
      @env.delete var
      queue UnsetCommand.new(var)
    end

    ##
    # Change directory
    def cd(dir)
      dir << '/' unless dir.end_with? '/'
      @workdir = @workdir.join(dir)
      queue ChangedirectoryCommand.new(dir)
    end

    ##
    # Copy file -> location
    def cp(f, name)
      name.magic_format if name.respond_to? :magic_format
      queue CopyCommand.new(f, name)
    end

    ##
    # Run a shell command
    def sh(cmd)
      queue ShCommand.new(cmd)
    end

    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end
end
