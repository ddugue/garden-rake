require 'rake/garden/chore'
require 'rake/garden/file_chore'
require 'rake/garden/commands/sync'
require 'rake/garden/command_context'

module Rake::Garden
  ##
  # Chore that decorate
  ##
  class CommandChore < Chore
    include CommandsContext

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        @force = true
      elsif prerequisite_name.instance_of? String and prerequisite_name.include? "."
        return FileChore.new(prerequisite_name, @application)
      else
        return super prerequisite_name.to_s
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
      until completed  do
        completed = true
        for cmd in @queue do
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

    def execute(args=nil)
      @logger.info " "
      @logger.important " Running Task: " + name.capitalize.bold
      start = Time.now
      super args

      # Once the queue is filled we execute all the waiting commands
      run and wait

      @skipped =   @queue.count { |cmd| cmd.skip? } || 0
      @succeeded = !@queue.any? { |cmd| cmd.error? }

      @queue.each { |cmd| cmd.log(@logger)}

      @output_files = @queue \
                        .map { |cmd| cmd.output_files } \
                        .reject { |cmd| cmd.nil? } \
                        .reduce(FileSet.new, :+)

      @logger.info(@logger.line(char:"="))
      result = " Result for #{name.capitalize.bold}: "
      result += "Success? #{@succeeded ? "Yes".green : "No".red}, "
      result += "Skipped: #{@skipped.to_s.yellow}, "
      result += "Total user time: #{@logger.render_time(Time.now - start).blue}, "
      result += "Changed files: #{output_files.length.to_s.bold}"
      @logger.important(result)
      @logger.info(" ")
    end

    ##
    # We force the execution if the rakefile changed since last execution
    def needed?
       return (has_changed(@application.rakefile) or super)
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
