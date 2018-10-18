# frozen_string_literal: true

require 'rake/garden/logger'
require 'rake/garden/command_args'

require 'rake/garden/async'
require 'rake/garden/fileset'
module Garden
  ##
  # AbstractCmd represent an abstract command that can be queued and run
  class Command
    include AsyncLifecycle

    attr_accessor :input_files  # FileSet of input files
    attr_accessor :output_files # Fileset of output files

    attr_writer :workdir        # Workdirectory for command
    attr_writer :env            # Environment variables

    ##
    # Parse arguments received by the initializer
    def parse_args(args, kwargs)
      return unless self.class.Args
      command_args = self.class.Args.new(*args, **kwargs)
      command_args.validate
      command_args
    end

    ##
    # Get the line number from which this command was invoked in the rakefile
    def line_number
      location = caller_locations.find do |loc|
        loc.path.include? 'rakefile'
      end
      location ? location.lineno : 0
    end

    def initialize(*args, **kwargs)

      @workdir = nil
      @env = nil
      @linenumber = line_number

      @input_files = Fileset.new
      @output_files = Fileset.new

      parse_args(args, kwargs)
    end

    ##
    # Iterate over output_files
    def each(&block)
      return enum_for(:each) unless block_given?
      output_files.each { |f| f.each(&block) }
    end

    ##
    # Render the prefix of the status
    # The prefix consist of the queue number, and the source of the execution
    def status_prefix
      " #{Logger.hierarchy execution_order}rakefile:#{@linenumber.to_s.bold} "
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
      time = Logger.time(self.time).to_s.blue
      "[#{status_text.colorize(status_color)}] ... #{time}"
    end

    ##
    # Return the status message for the command
    def status(max_size)
      prefix = status_prefix
      suffix = status_suffix
      max_size -= (suffix.uncolorize.length + 2 + prefix.uncolorize.length)
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

    def skip?; end
    ##
    # Return a fileset of file, assuming every file is NOT a glob
    # for glob, use +to_glob+
    def to_file(file)
      return Fileset.new(file.map { |f| to_file(f) }) if file.is_a? Array
      return Filepath.new(@workdir + file) if @workdir
      Filepath.new(file)
    end

    ##
    # Return a fileset built from a glob
    def to_glob(glob)
      return Fileset.new(glob.map { |g| to_glob(g) }) if glob.is_a? Array
      return Fileset.from_glob(@workdir + glob) if @workdir
      Fileset.from_glob(glob)
    end

    class << self; attr_accessor :Args end
  end
end
