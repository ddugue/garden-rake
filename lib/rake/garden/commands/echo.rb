# frozen_string_literal: true

require 'rake/garden/command'
require 'rake/garden/command_args'

module Garden
  ##
  # Represent the args of the echo cmmand
  class EchoArgs < CommandArgs
    attr_reader :message
    def validate
      @message ||= format_file(get(0))
    end
  end

  ##
  # Command that simply outputs a simple message
  class EchoCommand < Command
    @Args = EchoArgs

    def log(logger)
      prefix = status_prefix
      logger.info(prefix + @args.message)
    end
  end
end
