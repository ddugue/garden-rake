require 'rake/garden/logger'
module Garden
  ##
  # AbstractCmd represent an abstract command that can be queued and run
  class Command
    # FileSet of input files
    attr_accessor :input_files

    # Fileset of output files
    attr_accessor :output_files

    attr_writer :workdir  # Workdirectory for command
    attr_writer :env      # Environment variable

    attr_writer :loglevel # Log Level for messages

    def initialize(*_args, workdir: nil, env: nil, **kwargs)
      @workdir = workdir || Dir.pwd
      @env = env || {}
      @linenumber = caller_locations.find do |loc|
        loc.path.include? 'rakefile'
      end.lineno
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
    # Render the prefix of the status
    # If parent is provided, it means it should log as a sub-entry
    # The prefix consist of the queue number, and the source of the execution
    def status_prefix(parent = nil)
      pos = Logger.render_index @order, parent
      [
        pos.length + @linenumber.to_s.length + 10,
        "#{pos} rakefile:#{@linenumber.to_s.bold}"
      ]
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
      time = Logger.render_time(@time).to_s.blue
      [
        status_text.length + 7 + 6,
        "[#{status_text.colorize(status_color)}] ... #{time}"
      ]
    end

    ##
    # Return the status message fo the command
    def status(parent = nil)
      prefix_size, prefix = status_prefix parent
      suffix_size, suffix = status_suffix
      size = Logger.terminal_width - (suffix_size + prefix_size) + 9
      cmd = "'#{Logger.truncate_s(to_s, size).colorize(status_color)}'"
      cmd = cmd.ljust size
      "#{prefix} #{cmd} #{suffix} "
    end

    ##
    # Log command result
    def log(logger, parent = nil)
      logger.info(status(parent))
    end

    ##
    # Run the command
    # We don't include it in initialize. It allows to set up some intermediary
    # variable
    def run(order)
      @order = order
      @time = 0 if skip?
      self
    end

    ##
    # Wait and set the time it took to execute
    # Does not actually wait for the command to complete. Sets the time if the
    # command completed. By default it is instataneous. Will return nil if
    # command is not done
    def wait
      @time ||= 0
    end

    ##
    # Render a readeable version of the command
    def to_s
      'Abstract Command'
    end

    ##
    # Wait and return the result of this command
    def result
      nil
    end
  end
end
