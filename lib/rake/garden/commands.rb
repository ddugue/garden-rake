
module Rake::Garden
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
      pos = logger.render_index @order
      time = logger.render_time(@time)
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

      cmd = "'#{logger.truncate_s(to_s, cmd_size - 1).colorize(color)}'".ljust cmd_size
      logger.info "#{prefix} #{cmd} [#{status.colorize(color)}] ... #{time.to_s.blue} "
    end

    ##
    # Run the command
    # We don't include it in initialize. It allows to set up some intermediary variable
    def run order
      @order = order
      @linenumber = caller_locations.find { |loc| loc.path.include? 'rakefile' }.lineno
      @time = 0 if skip?
      self
    end

    ##
    # Wait and set the time it took to execute
    # Does not actually wait for the command to complete. Sets the time if the command
    # completed. By default it is instataneous. Will return nil if command is not done
    def wait
      @time = 0
    end

    ##
    # Render a readeable version of the command
    def to_s
      "Abstract Command"
    end

    ##
    # Return the affected file of this command
    def output_files
      nil
    end

    ##
    # Wait and return the result of this command
    def result
      nil
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
    # Returns wether the execution is done and successful
    def success?
      @thread and @thread.value.exitstatus == 0
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
      super
    end

    def log logger
      super
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

    def result
      while @time.nil?
        wait
        sleep(0.01)
      end
      @stdout
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
    def initialize(from, to)
      @from = from
      @to = to.format_with_file!
      super()
    end

    def skip?
      @skip = File.safe_mtime(@to) > File.safe_mtime(@from) if @skip.nil?
      @skip
    end

    def to_s
      "Copying #{@from} to #{@to}"
    end

    def command
      "mkdir -p #{Pathname.new(@to).dirname} && cp #{@from} #{@to}"
    end

    def output_files
      @skip ? nil : FileSet.new([@to])
    end
  end

  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class SetCommand < AbstractCommand
    def initialize(task, *args)
      if args.length > 1
        # first arg is a symbol, second is value
        @dict = {args[0].to_s => args[1].to_s}
      elsif args.length == 1
        # first arg is a dict
        raise "Set argument must be an hash" if not args[0].is_a? Hash
        @dict = Hash[args[0].map { |k, v| [k.to_s, v.to_s] }]
      else
        raise 'Invalid syntax for set. Please see docs'
      end

      task.env.merge! @dict
    end

    def to_s
      a = @dict.to_a
      "Setting up flag #{a[0][0]} to #{a[0][1]}"
    end
  end

  ##
  # Unsetcommand unset an environment variable
  # We mostly create a command for logging purpose
  class UnsetCommand < AbstractCommand
    def initialize(task, var)
      @var = var
      task.env.delete @var
    end

    def to_s
      "Unsetting up flag #{@var}"
    end
  end

  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < AbstractCommand
    def initialize(task, to)
      @to = to
      @to << '/' unless @to.end_with? '/'
      task.workdir = task.workdir.join(@to)
    end

    def to_s
      "Changing directory to #{@to}"
    end
  end

  ##
  # Command that wraps a sh
  class ShCommand < Command
    def initialize(cmd)
      if cmd.is_a? String
        cmd = ShArgs.new nil, cmd
      end
      @cmd = cmd.command
      @input = cmd.input || []
      @output = cmd.output || []
      super()
    end

    def command
      @cmd
    end

    def skip?
      if @skip.nil?
        min_output = @output.map { |f| File.safe_mtime f }.min || Time.at(0)
        max_input = @input.map { |f| File.safe_mtime f }.max || Time.at(12147483647)
        @skip = max_input < min_output
      end
      @skip
    end
  end
end
