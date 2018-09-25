require 'rake/garden/noop'
require 'rake/garden/chore'
require 'rake/garden/file_chore'
require 'rake/garden/commands/sync'
require 'rake/garden/async'
require 'rake/garden/command_context'

module Garden
  ##
  # Chore that is meant to contain +Command+
  class CommandChore < Chore
    include CommandsContext
    include AsyncManager

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true || prerequisite_name == 'true'
        @force = true
        Noop.new @application
      elsif (prerequisite_name.instance_of? String) \
            && ((prerequisite_name.include? '.') || (prerequisite_name.include? '*'))
        FileChore.new(prerequisite_name, @application)
      else
        super prerequisite_name.to_s
      end
    end

    def asyncs
      @queue
    end
    # def initialize(task_name, app)
    #   super
    # end

    # def wait_for(id=:all)
    #   completed = false
    #   until completed
    #     completed = true
    #     @queue.each do |process|
    #       process.tick
    #       completed = !process.running? & completed if id == :all
    #       completed = !process.running? if id == process.id
    #     end
    #     sleep(0.0001)
    #   end
    # end


    ##
    # Start to run all command asynchronously
    # def run
    #   @queue.each_with_index { |item, index| item.start(index) }
    # end

    # def skipped
    #   @skipped ||= @queue.count(&:skip?) || 0
    # end

    # def succeeded?
    #   @succeeded = @queue.none?(&:error?)
    # end

    def output_files
      @output_files ||= @queue \
                        .map(&:output_files) \
                        .reject(&:nil?) \
                        .reduce(FileSet.new, :+)
    end

    ##
    # Output a string for the result
    def status(max_size=nil)
      " Result for #{title}: " \
      + "Success? #{succeeded? ? 'Yes'.green : 'No'.red}, " \
      + "Skipped: #{skips.to_s.yellow}, " \
      + "Total user time: #{Logger.render_time(time).blue}, " \
      + "Changed files: #{output_files.length.to_s.bold}"
    end

    def execute(args = nil)
      @logger.info ' '
      @logger.important " Running Task: #{title}"
      super args
      start

      result # This wait for all the commands for result

      @queue.each { |cmd| cmd.log(@logger) }

      @logger.info(Logger.line(char: '='))
      @logger.important(status)
      @logger.info(' ')
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def needed?
      changed?(@application.rakefile) || super
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
