
module Rake::Garden
  ##
  # Logging class that enables the user to time an execution
  # start: Time object that represent the start of a program (normally rake)
  # verbose: Wether to output message or not. Default use ENV["VERBOSE"] or True
  ##
  class Logger
    @@start = Time.now

    def initialize(start=nil, verbose=nil)
      @verbose = verbose || (ENV.fetch('VERBOSE', 'true') == 'true')
      @absolute_start = start || @@start # Start of the program
      @start = Time.now                  # Start of the current execution
    end

    # Function responsible to render a time either in ms or sec
    def render_time(time)
      time < 1 ? "#{(time * 1000).round(2)}ms" : "#{time.round(2)}s"
    end

    # Puts text since the start of the execution
    def log(text)
      if @verbose
        exec_time = render_time(Time.now - @start)
        total_time = render_time(Time.now - @absolute_start)
        puts "[#{exec_time} / #{total_time}] #{text}"
      end
    end
  end
end
