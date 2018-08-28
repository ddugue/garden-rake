require 'open3'
require 'time'

require 'rake/garden/ext/file'

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden

  ##
  # Command that wraps an Open3 process
  class ShCommand < Command

    def initialize(cmd)
      if cmd.is_a? String
        cmd = Args.new nil, cmd
      end
      @cmd = cmd.command
      @input = cmd.input || []
      @output = cmd.output || []
      super()
    end

    def skip?
      if @skip.nil?
        min_output = @output.map { |f| File.safe_mtime f }.min || Time.at(0)
        max_input = @input.map { |f| File.safe_mtime f }.max || Time.at(12147483647)
        @skip = max_input < min_output
      end
      @skip
    end

    def output_files
      @skip ? nil : FileSet.new(@output)
    end
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
      @stdin, @stdout, @stderr, @thread = Open3.popen3(@env, @cmd, :chdir=>@workdir) unless skip?
      super
    end

    def log logger, prefix=nil
      super
      if @stdout
        logger.debug "#{' ' * 7}Running: #{@cmd}"
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

    def to_s
      @cmd
    end
  end
end
