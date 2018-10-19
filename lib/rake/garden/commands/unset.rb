# frozen_string_literal: true

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args for the command set
  class UnsetArgs < CommandArgs
    @syntax = <<~SYNTAX
      Make sure you have the right syntax for command 'unset'
      The acceptable form for unset is the following:
      * unset 'key'
    SYNTAX
    INVALID_LENGTH = 'The number of arguments is invalid'

    def validate
      raise ParsingError.new(self, INVALID_LENGTH) if length.zero?
    end

    ##
    # Return the key that is being set for the +value+
    def key
      @key ||= get(0).to_s
    end
  end

  ##
  # Command that sets an environment variable
  # We mostly create a command for logging purpose
  class UnsetCommand < Command
    @Args = UnsetArgs

    def initialize(*args, **kwargs)
      super
      @manager&.env.delete @args.key
    end

    def to_s
      "Unsetting up flag #{@args.key}"
    end
  end
end
