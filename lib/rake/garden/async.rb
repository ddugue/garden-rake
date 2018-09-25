# frozen_string_literal: true

module Garden
  ##
  # Represent an Async object lifecycle
  # - Start its process or skip
  # - Update status until completion by async manager
  # - Call on_complete when done by tick
  module AsyncLifecycle
    attr_accessor :execution_order # Order of the execution of this async block
    attr_accessor :manager # The manager responsible for executing the lifecycle

    # Start executing the lifecycle
    def start(order = nil)
      @start_time = Time.now
      @execution_order = order
      if skip?
        on_skip
      else
        process
      end
      self
    end

    # @abstract
    # The AsyncLifecycle should implement a method process
    # or else it will fail with name error

    # Returns wether this object should skip its execution
    def skip?
      false
    end

    # Executes when the object is skipped
    def on_skip
      @end_time = Time.now
    end

    # +update_status+ method will be called repeatedly by the manager
    # to ensure the lifecycle updates its status
    def update_status
      on_complete if completed? && @end_time.nil?
    end

    # Executed by +update_status+ when the task just completed
    def on_complete
      @end_time = Time.now
    end

    # Wait for result and returns the value
    def result
      manager&.wait_for(execution_order)
      nil
    end

    # Returns the time it took to complete the lifecycle
    def time
      @end_time - @start_time
    end

    ##
    # STATUS
    # The following methods return the status of the lifecycle
    ##
    # Returns wether the lifecycle is completed
    def completed?
      !@start_time.nil?
    end

    # Returns wether the object is currently running and not completed
    def running?
      !@start_time.nil? && @end_time.nil?
    end

    # Returns wether there was an error in the execution
    def error?
      completed? && false
    end

    # Returns wether there was no error in the execution
    def succeeded?
      completed? && !error?
    end
    ##
    # End of STATUS
    ##
  end
end
