# coding: utf-8

module Rake::Garden
  ##
  # Logging class that enables flushing for parallel execution
  ##
  class Logger
    NONE = 0      # Output only errors
    IMPORTANT = 1 # Output minimal information
    INFO = 2      # Output all executed commands
    VERBOSE = 3   # Output all stdout
    DEBUG = 4     # Output garden debug information as well

    attr_accessor :level # Log level of the Logger

    def initialize(level: INFO)
      @level = level
      @output = []
      @errors = []
    end

    ##
    # Return terminal width
    def terminal_width
      Rake.application.terminal_width
    end

    ##
    # Render a time with max 6 char
    def render_time(time)
      if time < 10
        "#{time.round(3)}s"
      elsif time >= 3600
        "#{(time / 3600).floor}h#{(time % 3600 / 60).floor.to_s.ljust(2, "0")}m"
      elsif time >= 60
        "#{(time / 60).floor}m#{(time % 60).floor}s"
      else
        "#{time.round(2)}s"
      end
    end

    ##
    # Render a single index
    def render_index(nb, prefix=nil, nbdigits: 3)
      if prefix
        " " * 4 + "└[#{prefix}.#{nb}]"
      else
        "[#{nb}]".rjust nbdigits + 3
      end
    end

    ##
    # Crop a long string with ...
    def truncate_s s, length = 30, ellipsis = '...'
      if s.length > length
        s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
      else
        s
      end
    end

    ##
    # Return a line of character
    def line(char: '-')
      " " + char * (terminal_width - 2) + " "
    end

    ##
    # Return a string padded with space
    # Left: number of char to the left
    # Rigth: size of the text to the right default to text length
    def align_right(text, left: 0, right: nil)
      " " * (terminal_width - 1 - left - (right || text.length)) + text
    end

    ##
    # Join all stream of text into
    def join(strings)
      sep = $\ || "\n"
      strings.map { |s|
        next if s.nil?
        s.end_with?(sep) ? s : s + sep
      }.join
    end

    ##
    # Print output to stdout
    def flush
      $stdout.print(join(@output))
      $stderr.print(join(@errors))
      @output.clear
      @errors.clear
    end

    ##
    # Outputs error to stderr
    def error(txt)
      @errors << txt.red
    end

    ##
    # Outputs important information to stdout
    def important(txt)
      @output << txt if @level >= IMPORTANT
    end

    ##
    # Outputs information to stdout
    def info(txt)
      @output << txt if @level >= INFO
    end

    ##
    # Outputs additional information to stdout
    def verbose(txt)
      @output << txt.light_black if @level >= VERBOSE
    end

    ##
    # Outputs debug information to stdout
    def debug(txt)
      @output << txt.light_black if @level >= DEBUG
    end

  end
end
