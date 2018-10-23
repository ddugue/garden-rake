# frozen_string_literal: true

require 'rake/garden/chore'
require 'rake/garden/fileset'

module Garden
  ##
  # FileChore
  # FileChore is a task that encapsulate files, it is used to know if a task
  # should execute, see +Chore+
  class FileChore < Chore
    def initialize(task_name, app)
      @pattern = task_name
      super task_name, app
    end

    def output_files
      @output_files ||= Fileset.from_glob(@pattern)
    end
  end
end
