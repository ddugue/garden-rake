
module Rake::Garden
  class Logger
    include Singleton
    def initialize
      @start = Time.now
    end

    def verbose?; ENV.fetch("VERBOSE", "true") == "true"; end

    def render_time(time)
      time < 1 ? "#{(time * 1000).round(2)}ms" : "#{time.round(2)}s"
    end

    # Start a timer
    def start(); @time = Time.now; end
    def stop(); @time = nil; end

    # Log time since start on top of total time
    def log(text)
      if verbose?
        exec_time = render_time(@start.nil? ? 0 : Time.now - @time)
        total_time = render_time(Time.now - @start)
        puts "[#{exec_time} / #{total_time}] #{text}"
      end
    end
  end
end
