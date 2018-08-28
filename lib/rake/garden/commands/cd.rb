require 'rake/garden/command'

module Rake::Garden
  ##
  # Command that represents a change directory
  class ChangedirectoryCommand < Command
    def initialize(task, to)
      @to = to
      @to << '/' unless @to.end_with? '/'
      task.workdir = task.workdir.join(@to)
      super()
    end

    def to_s
      "Changing directory to #{@to}"
    end
  end
end
