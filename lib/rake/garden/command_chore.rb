require 'rake/garden/chore'
require 'rake/garden/file_chore'
require 'rake/garden/commands/sync'
require 'rake/garden/command_context'

module Garden
  ##
  # Chore that decorate
  ##
  class CommandChore < Chore
    include CommandsContext

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        @force = true
        nil
      elsif (prerequisite_name.instance_of? String) \
            && (prerequisite_name.include? '.')
        FileChore.new(prerequisite_name, @application)
      else
        super prerequisite_name.to_s
      end
    end

    def initialize(task_name, app)
      @skipped = 0
      super
    end

    ##
    # Wait for all task to complete
    def wait
      completed = false
      until completed
        completed = true
        @queue.each do |cmd|
          completed = !cmd.wait.nil? & completed
        end
        sleep(0.0001)
      end
    end

    ##
    # Start to run all command asynchronously
    def run
      @queue.each_with_index do |item, index|
        item.run(index)
      end
    end

    def skipped
      @skipped ||= @queue.count(&:skip?) || 0
    end

    def succeeded?
      @succeeded = @queue.none?(&:error?)
    end

    def output_files
      @output_files ||= @queue \
                        .map(&:output_files) \
                        .reject(&:nil?) \
                        .reduce(FileSet.new, :+)
    end

    def title
      name.capitalize.bold
    end
    ##
    # Output a string for the result
    def result(time)
      " Result for #{title}: " \
      + "Success? #{succeeded? ? 'Yes'.green : 'No'.red}, " \
      + "Skipped: #{skipped.to_s.yellow}, " \
      + "Total user time: #{time.blue}, " \
      + "Changed files: #{output_files.length.to_s.bold}"
    end

    def execute(args = nil)
      @logger.info ' '
      @logger.important " Running Task: #{title}"
      start = Time.now
      super args

      # Once the queue is filled we execute all the waiting commands
      run && wait
      time = Logger.render_time(Time.now - start)

      @queue.each { |cmd| cmd.log(@logger) }

      @logger.info(@logger.line(char: '='))
      @logger.important(result(time))
      @logger.info(' ')
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def needed?
      changed(@application.rakefile) || super
    end

    ##
    # Run a block in sync mode
    def sync(&block)
      queue SyncCommand.new(&block)
    end

    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end
end
