# frozen_string_literal: true

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args for the command set
  class SetArgs < CommandArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'set'
      The acceptable forms for cd are the following:
      * set 'key', 'value'
      * set :key, 'value'
      * set 'key' => 'value'
      * set :key => 'value'
      * set key: value
    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'
    INVALID_VALUE = "You can't set up multiple variable at once"

    def validate
      case @args.length
      when 0 then raise ParsingError.new(self) if @kwargs.empty?
      when 1 then raise ParsingError.new(self) unless @args[0].is_a? Hash
      when 2 then raise ParsingError.new(self, INVALID_VALUE) if @args[0].is_a? Hash
      else raise ParsingError.new(self, INVALID_LENGTH) if length > 2
      end
    end

    def args
      case @args.length
      when 0 then @kwargs.to_a[0]
      when 1 then @args[0].to_a[0]
      when 2 then @args
      end
    end

    ##
    # Return the key that is being set for the +value+
    def key
      @key ||= get(0).to_s
    end

    ##
    # Return the value that is being set for the +key+
    def value
      @value ||= get(1).to_s
    end
  end

  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class SetCommand < Command
    @Args = SetArgs

    def initialize(*args, **kwargs)
      super
      @manager.env[@args.key] = @args.value
    end

    def to_s
      "Setting up flag #{@args.key} to #{@args.value}"
    end
  end
end
