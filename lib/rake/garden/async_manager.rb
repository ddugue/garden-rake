# frozen_string_literal: true

require 'rake/garden/async'

module Garden
  ##
  # Async manager is a manager that executios other async object
  module AsyncManager
    include AsyncLifecycle

    def asyncs
      []
    end

    # Wait for all (if +id+ == :all) async process to complete or a specific one
    # whose prcocess id is +id+ if +id+ is not equal to :all
    def wait_for(id = :all)
      asyncs.each_with_index { |item, index| item.start(index) }
      completed = false
      until completed
        completed = true
        asyncs.each do |process|
          process.update_status
          completed = process.completed? & completed if id == :all
          completed = process.completed? if id == process.execution_order
        end
        sleep(0.0001)
        if id == :all
          @completed = completed
          update_status
        end
      end
    end

    # Alias for wait_for all
    def result
      wait_for :all
    end

    def on_complete
      super
      @logger.debug " Completed #{to_s}" unless @logger.nil?
    end

    def should_complete
      @completed
    end

    def completed?
      @completed
    end

    ##
    # Return the number of async blocks that should be skipped
    def skips
      @skips ||= asyncs.count(&:skipped?) || 0
    end

    # Return the number of async blocks that suceeded
    def successes
      @successes ||= asyncs.count(&:succeeded?) || 0
    end

    # Return wether all the async blocks succeeded
    def succeeded?
      @succeeded = asyncs.none?(&:error?) if @succeeded.nil?
      @succeeded
    end

    # Returns wether there was an error in the execution
    def error?
      @succeeded == false || asyncs.any?(&:error?)
    end
  end
end
