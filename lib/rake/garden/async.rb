# frozen_string_literal: true

##
# Represent an Async object lifecycl
# - Start
# - tick until completion by async manager
# - on_complete callback
module Async
  attr_accessor :execution_order # Order of the execution of this async block
  attr_accessor :manager

  def completed?
    !@start_time.nil?
  end

  def running?
    !@start_time.nil? && @end_time.nil?
  end

  def error?
    completed? && false
  end

  def succeeded?
    completed? && !error?
  end

  def skip?
    false
  end

  def result
    manager&.wait_for(execution_order)
    nil
  end

  def time
    return 0 if skip?
    @end_time - @start_time
  end

  def on_end(&block)
    @on_complete.push(block)
  end

  def on_complete
    @end_time = Time.now
  end

  def start(order = nil)
    @start_time = Time.now
    @execution_order = order
    process unless skip?
    self
  end

  def tick
    on_complete if completed? && @end_time.nil?
  end

  def status(max_width = nil); end

  def process(); end
end

##
# Async manager is a manager that executios other async object
module AsyncManager
  include Async

  # def asyncs
  #   []
  # end

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
