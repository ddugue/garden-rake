# frozen_string_literal: true

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args of the echo cmmand
  class EchoArgs < CommandArgs
    def message
      get(0).to_s
    end
  end

  ##
  # Command that simply outputs a simple message
  class EchoCommand < Command
    @Args = EchoArgs

    def parse_args(args, kwargs)
      parsed_args = super
      @message = parsed_args.message
    end

    def log(logger)
      prefix = status_prefix
      logger.info(prefix + @message)
    end

    def process; end
  end
end
