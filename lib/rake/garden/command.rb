require 'rake/garden/logger'
require 'rake/garden/command_args'

require 'rake/garden/async'
module Garden
  ##
  # AbstractCmd represent an abstract command that can be queued and run
  class Command
    include Async

    attr_accessor :input_files  # FileSet of input files
    attr_accessor :output_files # Fileset of output files

    attr_writer :workdir        # Workdirectory for command
    attr_writer :env            # Environment variables

    ##
    # Parse arguments received by the initializer
    def parse_args(args, kwargs)
      command_args = self.class.Args.new(*args, **kwargs)
      command_args.validate
      command_args
    end

    ##
    # Get the line number from which this command was invoked in the rakefile
    def get_line_number
      location = caller_locations.find do |loc|
        loc.path.include? 'rakefile'
      end
      location ? location.lineno : 0
    end

    def initialize(parent, *args, **kwargs)
      @parent = parent

      @workdir = nil
      @env = nil
      @linenumber = get_line_number

      parse_args(args, kwargs)
    end

    ##
    # Render the prefix of the status
    # The prefix consist of the queue number, and the source of the execution
    def status_prefix()
      "#{Logger.hierarchy execution_order}rakefile:#{@linenumber.to_s.bold} "
    end

    ##
    # Return the color of the status text, yellow for skip, red for error, green
    # for success
    def status_color
      if skip?
        :yellow
      elsif error?
        :red
      else
        :green
      end
    end

    ##
    # Return the status text of the command, skipped, error or success
    def status_text
      if skip?
        'skipped'
      elsif error?
        'error'
      else
        'success'
      end
    end

    ##
    # Return the suffix of the status long info
    def status_suffix
      time = Logger.render_time(self.time).to_s.blue
      "[#{status_text.colorize(status_color)}] ... #{time}"
    end

    ##
    # Return the status message fo the command
    def status(max_size)
      prefix = status_prefix
      suffix = status_suffix
      max_size = max_size \
                 - (suffix.uncolorize.length + 2 + prefix.uncolorize.length)
      cmd = "'#{Logger.truncate(to_s, max_size).colorize(status_color)}'"

      Logger.align(prefix, cmd, suffix)
    end

    ##
    # Log command result
    def log(logger)
      logger.info(status(Logger.terminal_width))
    end

    ##
    # Render a readeable version of the command
    def to_s
      'Abstract Command'
    end

    class << self; attr_accessor :Args end
  end
end
