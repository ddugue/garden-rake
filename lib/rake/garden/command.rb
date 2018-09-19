require 'rake/garden/logger'
require 'rake/garden/command_args'
module Garden
  ##
  # AbstractCmd represent an abstract command that can be queued and run
  class Command

    attr_accessor :input_files  # FileSet of input files
    attr_accessor :output_files # Fileset of output files

    attr_writer :workdir        # Workdirectory for command
    attr_writer :env            # Environment variables


    ##
    # We use the start order as the ID for the command
    def id
      @order
    end

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

      begin
        parse_args(args, kwargs)
      rescue ParsingError => error
        @syntax_error = error
      end
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      (!@syntax_error.nil?) || false
    end

    ##
    # Returns wether we should skip execution of this command
    def skip?
      false
    end

    ##
    # Render the prefix of the status
    # The prefix consist of the queue number, and the source of the execution
    def status_prefix()
      "#{Logger.hierarchy @order}rakefile:#{@linenumber.to_s.bold}"
    end

    ##
    # Return the color of the status text
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
    # Return the status text of the command
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
      time = Logger.render_time(time).to_s.blue
      "[#{status_text.colorize(status_color)}] ... #{time}"
    end

    ##
    # Return the status message fo the command
    def status()
      prefix = status_prefix
      suffix = status_suffix
      max_size = Logger.terminal_width \
                 - (suffix.uncolorize.length + 2 + prefix.uncolorzie.length)
      text = @syntax_error ? "Syntax error" : to_s
      cmd = "'#{Logger.truncate(text, max_size).colorize(status_color)}'"

      Logger.align(prefix, cmd, suffix)
    end

    ##
    # Log command result
    def log(logger)
      logger.info(status)
      @syntax_error.log(logger) unless @syntax_error.nil?
    end

    ##
    # Start the execution of the command
    def start(order)
      @order = order
      self
    end

    ##
    # Tick checks the status of the command and triggers related events
    # is meant to be called by parent
    def tick; end

    ##
    # Returns wether the command is actually running
    def running?
      false
    end

    ##
    # Wait and return the result of this command
    def result
      @parent.wait_for(id)
      nil
    end

    ##
    # Return the time it took to execute the command
    def time
      0
    end

    ##
    # Render a readeable version of the command
    def to_s
      'Abstract Command'
    end

    class << self; attr_accessor :Args end
  end
end
