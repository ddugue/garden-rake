require 'etc'
## TODO: Abstract some dep away
module Rake::Garden
  ##
  # Utility to execute actions in parallel via threads
  ##
  class Parallel
    include Singleton
    def initialize
      @threads = []
      @executing = []
      @queue = Queue.new

      @commands = []

      @unlocked = false
      @start = true
      Etc.nprocessors.times do |i|
        @threads << Thread.new do
          while @start
            if @unlocked and !@queue.empty?
              @executing[i] = true
              system @queue.pop
              @executing[i] = false
            end
          end
        end
      end
    end

    ##
    # Lock the process, making him unable to receive new commands
    ##
    def lock
      @unlocked = false
    end

    ##
    # Unlock the thread, making him able to receive new commands
    ##
    def unlock
      @unlocked = true
    end


    ##
    # Queue a single command so it gets executed by the system
    ##
    def queue cmd
      @commands << cmd
      @queue << cmd
    end

    ##
    # Stop the threads
    ##
    def stop
      @start = false
      @threads.each do |thread|
        thread.join if !thread.nil?
      end
    end

    ##
    # Wait for the queue to be empty and execution to be done
    ##
    def wait
      while !(@queue.empty? || @executing.find { |obj| obj }) do
        sleep 0.1
      end
    end

    ##
    # Clean the notify list
    ##
    def clean
      @commands.clear
    end

    def with(metadata, &block)
      @clean

      $in_parallel = true
      block.call

      data = @watcher.with Watch.new ["."] do
        @unlock
        wait
        @lock
      end

      $in_parallel = false

      ###
      # Now we compare our notify with what SHOULD have been modified
      # and accessed, if they diverge, we will rerun the current block
      # sequentially
      ###

      reexecute = false
      accessed = Set.new
      outputs = Set.new

      @commands.each do |cmd|
        m = metadata.fetch(@command, {"dependencies" => Array.new, "outputs" => Array.new} )
        accessed += m["dependencies"].to_set
        outputs += m["outputs"].to_set
      end

      if data.accessed != accessed || data.outputs != outputs
        p "Need to reexecute block in sync mode"
        block.call
      end
    end
  end
end
