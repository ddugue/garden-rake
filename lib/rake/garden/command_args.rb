# frozen_string_literal: true

require 'rake/garden/context'

module Garden
  ##
  # Small data structure to pass Arguments to an SH Command
  class ParsingError < StandardError
    attr_reader :args

    def initialize(args, message = nil)
      @args = args
      @message = message
    end

    ##
    # Log syntax error
    def log(logger)
      logger.error(' ' + 'Error on rakefile:' + @args.linenumber.to_s.bold)
      logger.error(logger.class.line(char: '*'))
      logger.error(' ' + @message) if @message
      logger.error(@args.syntax.lines.map { |a| ' ' + a }.join)
    end
  end

  ##
  # Abstract object used to parse function arguments.
  # Allow a kind of overriding to provide different syntax for function calling.
  class CommandArgs
    attr_reader :args
    attr_reader :kwargs

    FILE_PATTERNS = <<~FILEPATTERNS
      * a single filename
      * a glob reprensenting multiple files
      * an enumerable object (ie the files object)
      * a literal array mixing glob/filenames
    FILEPATTERNS

    def initialize(cmd, *args, **kwargs)
      @cmd = cmd
      @args = args
      @kwargs = kwargs
    end

    ##
    # Returns the linenumber in the rakefile where command was created
    def linenumber
      return @cmd.nil? ? 0 : @cmd.linenumber
    end

    ##
    # Returns the length of the positional arguments
    def length
      @args.length
    end

    ##
    # Return wether the actual command args are valid
    # Raises a Parsing Error if the syntax is invalid
    def validate; end

    ##
    # Get value from args or kwargs if it is a symbol
    def get(index)
      args[index]
    end

    ##
    # Compare equality based on command args and kwargs
    def ==(other)
      return false unless other.is_a? CommandArgs
      @args == other.args && @kwargs == other.kwargs
    end

    ##
    # Append object to args
    def >>(other)
      @args.push(other)
      self
    end

    def to_s
      "(#{self.class}) Args: #{@args}, Kwargs: #{@kwargs}"
    end

    def syntax
      self.class.syntax
    end

    def context
      Context.instance
    end

    # Use file context to format a string if the file is present
    def format_file(str)
      return str unless context.file
      return str.map { |s| format_file(s) } if str.is_a? Array
      context.file.format(str.to_s)
    end

    class << self
      # syntax should be a multiline string to instruct on the usage of
      # the command
      attr_accessor :syntax

      ##
      # Create a new command args based on a command args
      def from(args)
        new(*args.args, **args.kwargs)
      end
    end
  end
end

##
# Overriding string class to provide helper for our dsl
class String
  def >>(other)
    d = [self, other]
    d.is_args = true
    d
  end
end

##
# Overriding Array class to provide helper for our dsl
class Array
  def >>(other)
    if (self.is_args)
      self << other
      self
    else
      d = [self, other]
      d.is_args = true
      d
    end
  end

  def to_a
    a = Array.new
    each do |item|
      if item.respond_to?(:is_args) && item.is_args
        a.concat(item)
      else
        a.append(item)
      end
    end
    a
  end

  attr_accessor :is_args
end
