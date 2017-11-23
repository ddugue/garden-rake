DEBUG = ENV.fetch("DEBUG", "false") == "true"

require 'rake'
require_relative './garden/logger.rb'
require_relative './garden/metadata.rb'
require_relative './garden/execute.rb'

module Rake::Garden

  # Shortcut functions
  def execute(command)
    exec = Executor.new(command)
    exec.execute()
  end

  at_exit { Metadata.instance.save() }
end
