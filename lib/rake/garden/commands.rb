
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

    def output_files
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

    def output_files
      @skip ? nil : FileSet.new([@to])
    end
  end

  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class SetCommand < AbstractCommand
    def initialize(dict, *args)
      @dict = dict
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
    def initialize(var, *args)
      @var = var
    end

    def to_s
      "Unsetting up flag #{@var}"
    end
  end

  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < AbstractCommand
    def initialize(to, *args)
      @to = to
    end

    def to_s
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
end
