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
      + "Output files: #{output_files.length.to_s.bold}"
    end

    def on_complete
      super
      @metadata['last_executed'] = Time.now.to_i unless error?
      return if @silenced
      @queue.each { |cmd| cmd.log(@logger) }
      @logger.info(Logger.line(char: '='))
      @logger.important(status)
      @logger.debug { " Files changed: #{output_files.to_a.map(&:to_s)}" }
      @logger.info(' ')
    end

    ##
    # Log some content after the execution
    def on_skip
      super
      @logger.important " Skipping Task: #{title} "
      @logger.debug(" Task was last executed #{@last_executed.to_i}")
      @logger.debug do
        info = input_files.to_a.map { |file| [file.to_s, file.mtime] }.to_h
        " Prerequisite tasks: #{info}"
      end
    end

    ##
    # Return wether the task need to be run
    # We run it only if prerequisites are empty or when one of its input
    # has been modified since last execution
    def should_skip
      if @needed.nil?
        @needed = prerequisite_tasks.empty? || \
                  input_files.since(@last_executed).any? || \
                  @force

        # We also make sure that if the rakefile was modified since last
        # execution, we force reexecution
        if @application.rakefile
          @needed ||= File.mtime(@application.rakefile) > @last_executed
        end
      end
      !@needed
    end

    def process
      # Instance exec decorate the context of the lambda with self methods
      @logger.info ' '
      @logger.important " Running Task: #{title} "
      begin
        @actions.each { |act| instance_exec(self, @args, &act) }
      rescue ParsingError => error
        error.log(@logger)
        @succeeded = false
      end
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
