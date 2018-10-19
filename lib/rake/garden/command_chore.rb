require 'rake/garden/chore'
require 'rake/garden/fileset'
require 'rake/garden/async'
require 'rake/garden/async_manager'
require 'rake/garden/commands/sync'
require 'rake/garden/command'
require 'rake/garden/command_dsl'

module Garden
  ##
  # Chore that is meant to contain +Command+ and is responsible for
  # their execution
  class CommandChore < Chore
    include CommandsDSL
    include AsyncManager

    def asyncs
      @queue
    end

    def output_files
      @output_files ||= Fileset.new(@queue)
    end

    ##
    # Output a string for the result
    def status(max_size=nil)
      " Result for #{title}: " \
      + "Success? #{succeeded? ? 'Yes'.green : 'No'.red}, " \
      + "Skipped: #{skips.to_s.yellow}, " \
      + "Total user time: #{Logger.time(time).blue}, " \
      + "Changed files: #{output_files.length.to_s.bold}"
    end

    def post_log
      if needed?
        @queue.each { |cmd| cmd.log(@logger) }
        @logger.info(Logger.line(char: '='))
        @logger.important(status)
        @logger.debug { " Files changed: #{output_files.to_a.map(&:to_s)}" }
      end
      @logger.info(' ')
      super
    end

    def execute(args = nil)
      super args
      start
      result # This wait for all the commands for result
    end

    ##
    # Run a block in sync mode
    def sync(&block)
      queue SyncCommand.new(&block)
    end

    class << self
      def define_task(options, *args, &block)
        chore = Rake.application.define_task(self, *args, &block)
        chore.options = options
        chore
      end
    end
  end
end
