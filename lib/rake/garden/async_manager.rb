# frozen_string_literal: true

##
# Async manager is a manager that executios other async object
module AsyncManager
  include Async

  def asyncs
    []
  end

  def process
    asyncs.each_with_index { |item, index| item.start(index) }
  end

  def wait_for(id = :all)
    until @completed
      @completed = true
      asyncs.each do |process|
        process.tick
        @completed = process.completed? & @completed if id == :all
        @completed = process.completed? if id == process.execution_order
      end
      tick if id == :all
      sleep(0.0001)
    end
  end

  def result
    wait_for :all
  end

  def completed?
    @completed
  end

  ##
  # Return the number of async blocks that should be skipped
  def skips
    @skips ||= asyncs.count(&:skip?) || 0
  end

  def successes
    @successes ||= asyncs.count(&:succeeded?) || 0
  end

  def succeeded?
    @succeeded = asyncs.none?(&:error?) if @succeeded.nil?
    @succeeded
  end
end
