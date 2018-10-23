# frozen_string_literal: true
require 'rake'

require 'rake/garden/command'
require 'rake/garden/command_args'
require 'rake/garden/metadata'

##
# Represent a daemon command
module Garden
  ##
  # Represent the Command arguments for SH
  class DaemonArgs < CommandArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'daemon'
      The acceptable forms for sh are the following:
      * daemon 'command'

      Where 'command' is the command to be executed
    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero? || length > 1
    end

    ##
    # Return a file aware string for the command
    def command
      @cmd ||= get(0)
    end
  end

  ##
  # Command that spawns a background process
  class DaemonCommand < Command
    @Args = DaemonArgs

    def metadata
      @metadata ||= JSONMetadata.metadata.namespace('daemons')
    end

    ##
    # Returns the PID of the process
    def pid
      @pid ||= metadata.fetch(@args.command, nil)
    end

    ##
    # Returns wether there is already a process running for current PID
    def process_exist?
      return false if pid.nil?
      begin
        Process.getpgid(pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    ##
    # Skip daemon spawning if the process is already running
    def should_skip
      @skip = process_exist? if @skip.nil?
      @skip
    end

    ##
    # Spawn and detach process linked to command
    def process
      pid = spawn(@args.command, %i[out err] => '/dev/null')
      Process.detach pid
      metadata[@args.command] = pid
    end

    def log(logger)
      super
      logger.debug logger.pad_for_hierarchy(@order, "Current PID: #{pid}")
    end

    def to_s
      "Spawning process '#{@args.command}'"
    end
  end

  task = Rake::Task.define_task('kill') do
    puts 'Killing all open daemon pids'
    pids = JSONMetadata.metadata.namespace('daemons')
    pids.each do |cmd, pid|
      puts "Closing PID #{pid} for command #{cmd}"
      begin
        Process.kill('QUIT', pid)
      rescue Errno::ESRCH
        puts "Process PID #{pid} has already been killed"
      end
    end
    pids.clear
    pids.save
  end
  # task.description = "Closes all opened daemon pids"
end
