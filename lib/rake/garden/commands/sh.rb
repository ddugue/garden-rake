require 'open3'
require 'time'

require 'rake/garden/ext/file'

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  MAX_TIME = Time.at(12_147_483_647)
  MIN_TIME = Time.at(0)

  ##
  # Command that wraps an Open3 process
  class ShCommand < Command
    def initialize(cmd)
      cmd = Args.new(nil, cmd) if cmd.is_a? String
      @cmd = cmd.command
      @input = cmd.input || []
      @output = cmd.output || []
      super
    end

    ##
    # Skip this command if all the input file are older than all the
    # output files
    def skip?
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
      @skip ? nil : FileSet.new(@output)
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      @thread && @thread.value.exitstatus != 0
    end

    ##
    # Returns wether the execution is done and successful
    def success?
      @thread && @thread.value.exitstatus.zero?
    end

    ##
    # Executes when the process is complete
    def on_complete
      @time ||= Time.now - @start
    end

    ##
    # Wait for process to complete
    # TODO: Make async process more developper friendy
    # ADD completed flag, make time a property
    # Merge wait and result
    def wait
      if @time.nil?
         on_complete unless @thread.status
      end
      @time
    end

    ##
    # Wrapper for popen3
    def popen3
      Open3.popen3(@env, @cmd, chdir: @workdir)
    end

    def run(order)
      @start = Time.now
      @stdin, @stdout, @stderr, @thread = popen3 unless skip?
      super
    end

    ##
    # Log stdout of the command
    def log_stdout(logger)
      return unless @stdout
      whitespace = ' ' * 7
      logger.debug "#{whitespace}Executing: #{@cmd}"
      @stdout.readlines.each do |line|
        line.strip!
        logger.verbose("#{whitespace}#{line}") unless line.empty?
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
    def log(logger, prefix = nil)
      super
      log_stdout(logger)
      log_stderr(logger)
    end

    def result
      while @time.nil?
        wait
        sleep(0.01)
      end
      @stdout
    end

    def to_s
      @cmd
    end
  end
end
