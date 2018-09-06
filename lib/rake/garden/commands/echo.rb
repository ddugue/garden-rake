require 'rake/garden/command'

module Garden
  ##
  # Command that simply outputs a simple message
  class EchoCommand < Command
    def initialize(msg)
      @msg = msg.format_with_file!
    end

    def log(logger, parent=nil)
      logger.info " #{':::::'.bold} #{@msg}"
    end
  end
end
