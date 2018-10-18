# coding: utf-8
# frozen_string_literal: true

require 'colorize'

module Garden
  ##
  # Logging class that enables flushing for parallel execution
  # Useful for executing async parallel task with one stdout
  #
  # Exposes +error+, +important+, +info+, +verbose+ and +debug
  # Each method will log to stdout only if Logger level is high enough
  # Each method can take a string or a block. Block will be executed only if
  # level is high enough and has precedence over text input
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

    # Print output to stdout and errors to stderr
    def flush
      $stdout.print(join(@output))
      $stderr.print(join(@errors))
      @output.clear
      @errors.clear
    end

    # Outputs error to stderr
    def error(txt)
      @errors << txt.red
    end

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

    def pad_for_hierarchy(*args)
      self.class.pad_for_hierarchy(*args)
    end

    private

    # Join all lines of text and ensures each one ends with \n
    def join(strings)
      sep = $OUTPUT_FIELD_SEPARATOR || "\n"
      strings.map do |string|
        next if string.nil?
        string.end_with?(sep) ? string : string + sep
      end.join
    end

    ##
    # We provide a set of utility functions to render nice looking text in
    # the terminal or in the log output
    class << self
      # Return a line of character with +char+
      def line(char: '-')
        ' ' + char * (terminal_width - 2) + ' '
      end

      # Return terminal width
      def terminal_width
        Rake.application.terminal_width
      end

      # Crop a long +string+ up to +length+ with an +ellipsis+
      def truncate(string, length = 30, ellipsis = '...')
        return string unless string.length > length
        string[0..(length - ellipsis.length - 1)] + ellipsis
      end

      # Render a +time+ with max 6 char
      def time(time)
        hours = time / 3600
        minutes = (time % 3600 / 60)
        case time
        when 0..9 then "#{time.round(3)}s".ljust(6)
        when 10..59 then "#{time.round(2)}s".ljust(6)
        when 60..3599 then "#{minutes}m#{(time % 60)}s".ljust(6)
        else "#{hours}h#{minutes.to_s.ljust(2, '0')}m".ljust(6)
        end
      end

      # Pad the text to provide a prefix with a number
      # useful to display list
      # Where +number+ is the number of this element in a list
      # where +nbdigits+ is the number of digits that we pad, default 3
      # where +tablevel+ in the amount of space character that constitutes a tab
      def hierarchy(number, nbdigits: 3, tablevel: 4)
        levels = number.to_s.count('.')
        return "[#{number}] ".rjust nbdigits + tablevel if levels.zero?
        (' ' * levels * tablevel) + "└[#{number}] " # When sub levels
      end

      # Align text with terminal witdth by making sure suffix is on the left
      # TODO: Add possibility of aligning right?
      def align(prefix, center, suffix)
        diff = terminal_width - 1 - (prefix + center + suffix).uncolorize.length
        "#{prefix}#{center}#{' ' * diff}#{suffix}"
      end

      # Pad based on the hierarchy level, used to display information
      # under an item made prefixed with a +hierarchy+ block
      def pad_for_hierarchy(number, message)
        (' ' * hierarchy(number).length) + message.to_s
      end
    end
  end
end
