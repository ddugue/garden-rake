
module Rake::Garden
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

    def initialize(loglevel: 1, workdir: nil, env: nil)
      @workdir = workdir || Dir.pwd
      @env = env || {}
      @linenumber = caller_locations.find { |loc| loc.path.include? 'rakefile' }.lineno
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
    def log logger, prefix=nil
      pos = logger.render_index @order, prefix
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
    # run the command
    # We don't include it in initialize. It allows to set up some intermediary variable
    def run order
      @order = order
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
end
