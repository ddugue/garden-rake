# frozen_string_literal: true

require 'open3'
require 'time'

require 'singleton' # FOR RAKE EARLY AND LATE
require 'rake/early_time'
require 'rake/late_time'

require 'rake/garden/filepath'
require 'rake/garden/fileset'

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden

  ##
  # Represent the Command arguments for SH
  class ShArgs < CommandArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'sh'
      The acceptable forms for sh are the following:
      * sh 'no_input_output_cmd --arg 7' (for commands with no output, no input)
      * sh 'input_files' >> 'no_output_cmd --arg 7' (for commands with no output)
      * sh 'input_files', 'no_output_cmd --arg 7' (for commands with no output)
      * sh 'input_files' >> 'no_output_cmd --arg 7' >> 'output_files'
      * sh 'input_files', 'no_output_cmd --arg 7', 'output_files'

      Where 'input_files' and 'output_files' are file patterns:
      #{CommandArgs::FILE_PATTERNS}
    SYNTAX
    CMD_NOT_STRING = 'The command must be a string'
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero? || length > 3
    end

    ##
    # Return a fileset group for input files
    def input
      @input ||= format_file(get(0)) if length >= 2
    end

    ##
    # Return a fileset group for output files
    def output
       @output ||= format_file(get(-1)) if length >= 3
    end

    ##
    # Return a file aware string for the command
    def command
      str = length == 1 ? get(0) : get(1)
      raise ParsingError.new(self, CMD_NOT_STRING) unless str.is_a?(String)
      @cmd ||= format_file(str)
    end
  end

  ##
  # Command that wraps an Open3 process
  class ShCommand < Command
    @Args = ShArgs

    def command
      @args.command
    end

    ##
    # Skip this command if all the input file are older than all the
    # output files
    def should_skip
      return true if super
      if @skip.nil?
        min_output = output_files.map(&:mtime).min || Rake::EARLY
        max_input = input_files.map(&:mtime).max || Rake::LATE
        @skip = max_input < min_output
      end
      @skip
    end

    ##
    # Return input files based on the provided output files
    def input_files
      @input_files ||= to_glob(@args.input)
    end

    ##
    # Return output files based on the provided output files
    def output_files
      @output_files ||= Fileset.new(to_file(@args.output))
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      super || ((@thread&.value&.exitstatus || 0) != 0)
    end

    ##
    # Returns wether the thread has finished executing
    def should_complete
      @skipped || (@thread && !@thread.status)
    end

    # Wrapper for popen3
    def popen3
      if @workdir
        Open3.popen3((@env || {}), command, chdir: @workdir)
      else
        Open3.popen3((@env || {}), command)
      end
    end

    def process
      @stdin, @stdout, @stderr, @thread = popen3
    end

    def running?
      @thread&.status
    end

    ##
    # Log stdout of the command
    def log_stdout(logger)
      return unless @stdout

      logger.debug logger.pad_for_hierarchy(@order, " Executing: #{command}")

      @stdout.readlines.each do |line|
        line.strip!
        next if line.empty?
        logger.verbose(logger.pad_for_hierarchy(@order, line))
      end
    end

    ##
    # Log stderr of the command
    def log_stderr(logger)
      return unless error?

      logger.error "****** There was an error running #{to_s.bold}: ******"
      stderr = @stderr.read

      return if stderr.strip.empty?
      logger.error stderr
      logger.error ' '
    end

    ##
    # Log stdout and stderr after the regular log
    def log(logger)
      super
      log_stdout(logger)
      log_stderr(logger)
    end

    ##
    # Return the result of this command
    def result
      super
      @stdout
    end

    def to_s
      command.to_s
    end
  end
end
