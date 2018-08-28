require 'rake/garden/command'

module Garden
  ##
  # Command that simply outputs a simple message
  class EchoCommand < Command
    def initialize(msg)
      @msg = msg
    end

    def log logger
      logger.info " #{":::::".bold} #{@msg}"
    end
  end
end
