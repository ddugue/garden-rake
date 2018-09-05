# coding: utf-8

require 'colorize'

module Garden
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
    # Return a line of character
    def line(char: '-')
      ' ' + char * (Logger.terminal_width - 2) + ' '
    end

    ##
    # Join all stream of text into
    def join(strings)
      sep = $\ || "\n"
      strings.map do |s|
        next if s.nil?
        s.end_with?(sep) ? s : s + sep
      end.join
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
    def important(txt = nil)
      return unless important?
      txt = yield if block_given?
      @output << txt
    end

    # Returns wether the logger will output important messages
    def important?
      @level >= IMPORTANT
    end

    ##
    # Outputs information to stdout
    def info(txt = nil)
      return unless info?
      txt = yield if block_given?
      @output << txt
    end

    # Returns wether the logger will output info level messages
    def info?
      @level >= INFO
    end

    ##
    # Outputs additional information to stdout
    def verbose(txt = nil)
      return unless verbose?
      txt = yield if block_given?
      @output << txt.light_black
    end

    # Returns wether the logger will output verbose level messages
    def verbose?
      @level >= VERBOSE
    end

    ##
    # Outputs debug information to stdout
    def debug(txt = nil)
      return unless debug?
      txt = yield if block_given?
      @output << txt.light_black
    end

    # Returns wether the logger will output debug messages
    def debug?
      @level >= DEBUG
    end

    class << self
      ##
      # Return terminal width
      def terminal_width
        Rake.application.terminal_width
      end

      ##
      # Crop a long string with ...
      def truncate_s(str, length = 30, ellipsis = '...')
        if str.length > (length - 4)
          str.to_s[0..(length - 4)].gsub(/[^\w]\w+\s*$/, ellipsis)
        else
          str
        end
      end

      ##
      # Render a time with max 6 char
      def render_time(time)
        if time < 10
          "#{time.round(3)}s"
        elsif time >= 3600
          "#{(time / 3600).floor}h#{(time % 3600 / 60).floor.to_s.ljust(2, '0')}m"
        elsif time >= 60
          "#{(time / 60).floor}m#{(time % 60).floor}s"
        else
          "#{time.round(2)}s"
        end
      end

      ##
      # Render a single index
      def render_index(number, prefix = nil, nbdigits: 3)
        if prefix
          ' ' * 4 + "└[#{prefix}.#{number}]"
        else
          "[#{number}]".rjust nbdigits + 3
        end
      end
    end
  end
end
