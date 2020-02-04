require 'rake/garden/command'
require 'rake/garden/command_dsl'

module Garden
  ##
  # Represent a block that will run synchronously
  class SyncCommand < Command
    include CommandsDSL

    def initialize(*arg, **kwargs, &block)
      @block = block
      @current_file = $CURRENT_FILE.dup
      @current_root = $CURRENT_ROOT.dup
      super
    end

    def wait_for(id)
      item = @queue.find { |process| process.execution_order == id }
      return if item.nil?

      completed = false
      until completed
        item.update_status
        completed = item.completed?
        sleep(0.0001)
      end
    end

    ##
    # Run the commands in sync
    def process
      # with_file @current_root, @current_file do
      instance_exec(self, &@block)
      # end

      index = 1
      @queue.each do |command|
        command.start "#{@order}.#{index}"
        command.result
        index += 1
      end
    end


    def to_s
      'Running following commands synchronously:'
    end

    ##
    # Log command result
    def log(logger)
      super
      @queue.each { |cmd| cmd.log(logger) }
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      @queue.any?(&:error?)
    end

    def output_files
      @output_files ||= Fileset.new(@queue)
    end

    ##
    # Wait and return the result of this command
    def result
      nil
    end
  end
end
