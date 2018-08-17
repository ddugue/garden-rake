require "rake/task.rb"
require "ostruct"
require 'time'
require 'set'
require 'json'
require 'pathname'
require 'colorize'
# require "rbtrace"

# TODO:
## Move output file to cmd
## Split files
## Create nice logging of chores
## Replace force? with needed? everywhere
## Create Cmd for  mv, sh!
## Create Cmd for sh
## Add command set for env
## Add cd for AbstractCmd
## Think about a way to add flags to build rake cmd
## Cleanup other files
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
  # AbstractCmd represent an abstract command that can be queued and run
  class AbstractCommand

    # FileSet of input files
    attr_accessor :input_files

    # Fileset of output files
    attr_accessor :output_files

    attr_writer :workdir  # Workdirectory for command
    attr_writer :env      # Environment variable
    attr_writer :origin   # Origin of the cmd in the rakefile (for debug purpose)
    attr_writer :loglevel # Log Level for messages

    def initialize(loglevel: 1, workdir: nil, env: nil)
      @workdir = workdir || Dir.pwd
      @env = env || {}
      @origin = caller_locations
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      false
    end

    ##
    # Returns wether we should skip execution of this command
    def skip?
      false
    end

    ##
    # Log command result
    def log logger
      pos = render_index @order
      time = render_time(@time)
      prefix_size = pos.length + @linenumber.to_s.length + 10
      prefix = "#{pos} rakefile:#{@linenumber.to_s.bold}"
      if skip?
        status = 'skipped'
        color = :yellow
      elsif error?
        status = 'error'
        color = :red
      else
        status = 'success'
        color = :green
      end

      suffix_size = status.length + 7 + 6
      cmd_size = logger.terminal_width - (2 + 4 + suffix_size + prefix_size) + 15

      cmd = "'#{truncate(to_s, cmd_size - 1).colorize(color)}'".ljust cmd_size
      logger.info "#{prefix} #{cmd} [#{status.colorize(color)}] ... #{time.to_s.blue} "
    end

    def run order
      @order = order
      @linenumber = get_line_number
      @time = 0 if skip?
      self
    end

    def wait
      @time = 0
    end

    def to_s
      "Abstract Command"
    end

  end

  ##
  # Command that wraps an Open3 process
  class Command < AbstractCommand

    ##
    # Returns wether there was an error in the execution
    def error?
      @thread and @thread.value.exitstatus != 0
    end

    ##
    # Wait for process to complete
    def wait
      if @time.nil?
        @time ||= Time.now - @start unless @thread.status
      end
      @time
    end

    def run order
      @start = Time.now
      @stdin, @stdout, @stderr, @thread = Open3.popen3(@env, command, :chdir=>@workdir) unless skip?
      super order
    end

    def log logger
      super logger
      if @stdout
        logger.debug "#{' ' * 7}Running: #{command}"
        for out_line in @stdout.readlines do
          logger.verbose("#{' ' * 7}#{out_line.strip}") if out_line.strip.length != 0
        end
      end

      if error?
        logger.error "****** There was an error running #{to_s.bold}: ******"
        stderr = @stderr.read
        if stderr.strip.length != 0
          logger.error stderr
          logger.error " "
        end
      end
    end

    def command
      ""
    end

    def to_s
      command
    end
  end

  ##
  # Abstract command that wraps a cp
  class CopyCommand < Command
    def initialize(from, to, *args)
      @from = from
      @to = to
      super *args
    end

    def skip?
      @skip = File.mtime(@to) >= File.mtime(@from) if @skip.nil?
      @skip
    end

    def to_s
      "Copying #{@from} to #{@to}"
    end

    def command
      "mkdir -p #{Pathname.new(@to).dirname} && cp #{@from} #{@to}"
    end
  end

  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < AbstractCommand
    def initialize(to, *args)
      @to = to
    end

    def to_s
      @to << '/' unless @to.end_with? '/'
      "Changing directory to #{@to}"
    end
  end

  ##
  # Command that wraps a sh
  class ShCommand < Command
    def initialize(cmd, *args)
      @cmd = cmd
      super *args
    end

    def command
      @cmd
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
      @logger.debug("#{render_index @command_index} Queuing '#{command.to_s}'")
      @queue << command.run(@command_index)
    end

    ##
    # Change directory
    def cd(dir)
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
