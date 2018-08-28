require 'rake/garden/command'
require 'rake/garden/command_context'

module Rake::Garden
  ##
  # Represent a block that will run synchronously
  class SyncCommand < Command
    include CommandsContext

    def initialize(&block)
      @block = block
      super()
    end

    ##
    # Run the commands in sync
    def run order
      start = Time.now
      @order = order
      index = 1
      self.instance_exec(self, &@block)
      for command in @queue
        command.run index
        while command.wait.nil?
          sleep(0.001)
        end
        index += 1
      end
      @time = Time.now - start
    end

    def wait
      @time
    end

    def to_s
      "Running following commands synchronously:"
    end

    ##
    # Log command result
    def log logger
      super logger
      @queue.each { |cmd| cmd.log(logger, @order)}
    end
    ##
    # Returns wether there was an error in the execution
    def error?
      @queue.any? { |cmd| cmd.error? }
    end

    ##
    # Return the affected file of this command
    def output_files
      @output_files ||= @queue \
                        .map { |cmd| cmd.output_files } \
                        .reject { |cmd| cmd.nil? } \
                        .reduce(FileSet.new, :+)
      @output_files
    end

    ##
    # Wait and return the result of this command
    def result
      nil
    end
  end
end
