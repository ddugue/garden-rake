require 'rake/garden/command'

module Rake::Garden
  ##
  # Unsetcommand unset an environment variable
  # We mostly create a command for logging purpose
  class UnsetCommand < Command
    def initialize(task, var)
      @var = var
      task.env.delete @var
      super()
    end

    def to_s
      "Unsetting up flag #{@var}"
    end
  end
end
