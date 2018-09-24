require 'open3'
require 'time'

require 'rake/garden/ext/file'
require 'rake/garden/filepath'
require 'rake/garden/fileset2'

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  MAX_TIME = Time.at(12_147_483_647)
  MIN_TIME = Time.at(0)

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

    def validate
      raise ParsingError.new(self) if (length == 0 or length > 3)
    end

    ##
    # Return a fileset group for input files
    def input
      FilesetGroup.new(length >= 2 ? get(0) : nil)
    end

    ##
    # Return a fileset group for output files
    def output
      FilesetGroup.new(length >= 3 ? get(-1) : nil)
    end

    ##
    # Return a file aware string for the command
    def command
      str = length == 1 ? get(0) : get(1)
      unless (str.is_a?(String) || str.is_a?(FileAwareString))
        raise ParsingError.new(self, "The command must be a string")
      end
      FileAwareString.create(str)
    end
  end

  ##
  # Command that wraps an Open3 process
  class ShCommand < Command
    @Args = ShArgs

    def parse_args(*args, **kwargs)
      args = super

      @cmd = args.command
      @input = args.input
      @output = args.output
    end

    def command
      @cmd.to_s
    end

    ##
    # Skip this command if all the input file are older than all the
    # output files
    def skip?
      return true if super
      if @skip.nil?
        min_output = @output.map { |f| File.safe_mtime f }.min || MIN_TIME
        max_input = @input.map { |f| File.safe_mtime f }.max || MAX_TIME
        @skip = max_input < min_output
      end
      @skip
    end

    ##
    # Return output files based on the provided output files
    def output_files
      @skip ? nil : @output
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      super || (@thread && @thread.value.exitstatus != 0)
    end

    ##
    # Returns wether the thread has finished executing
    def completed?
      # puts "#{@thread.status}"
      @thread && !@thread.status
    end

    # Wrapper for popen3
    def popen3
      Open3.popen3(@env, command, chdir: @workdir)
    end

    def process
      @stdin, @stdout, @stderr, @thread = popen3
    end

    def running?
      @thread && @thread.status
    end

    ##
    # Log stdout of the command
    def log_stdout(logger)
      return unless @stdout

      logger.debug logger.pad_for_hierarchy(@order, "Executing: #{@cmd}")

      @stdout.readlines.each do |line|
        line.strip!
        logger.verbose(logger.pad_for_hierarchy(@order, line)) unless line.empty?
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

    def result
      super
      @stdout
    end

    def to_s
      @cmd.to_s
    end
  end
end
