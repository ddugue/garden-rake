require 'rake/garden/chore'
require 'rake/garden/fileset'

module Rake::Garden
  ##
  # FileChore
  # FileChore is a task that encapsulate files, it is used to know if a task should
  # execute
  ##
  class FileChore < Chore
    def initialize(task_name, app)
      @pattern = task_name
      super task_name, app
    end

    def needed?
      true
    end

    def output_files
      @files ||= FileSet.new(Dir.glob(@pattern))
    end
  end
end
