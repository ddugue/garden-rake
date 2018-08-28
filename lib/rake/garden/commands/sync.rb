require 'rake/garden/command'
require 'rake/garden/command_context'

module Garden
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
    def run(order)
      start = Time.now
      @order = order

      instance_exec(self, &@block)

      index = 1
      @queue.each do |command|
        command.run index
        sleep(0.001) while command.wait.nil?
        index += 1
      end
      @time = Time.now - start
    end

    def to_s
      'Running following commands synchronously:'
    end

    ##
    # Log command result
    def log(logger)
      super
      @queue.each { |cmd| cmd.log(logger, @order) }
    end

    ##
    # Returns wether there was an error in the execution
    def error?
      @queue.any?(&:error?)
    end

    ##
    # Return the affected file of this command
    def output_files
      @output_files ||= @queue \
                        .map(&:output_files) \
                        .reject(&:nil?) \
                        .reduce(FileSet.new, :+)
    end

    ##
    # Wait and return the result of this command
    def result
      nil
    end
  end
end
