require 'rake/garden/logger'
require 'rake/garden/fileset'

module Garden
  ##
  # A chore is a task you do not want to execute or the execute it as needed
  # It tries to evaluate wether it should be executed or net
  class Chore < Rake::Task
    attr_reader :last_executed
    attr_reader :output_files

    def initialize(task_name, app)
      @output_files = FileSet.new
      @metadata = metadata.namespace(task_name)
      @last_executed = Time.at(@metadata.fetch('last_executed', 0) || 0)
      @logger = Logger.new(level: Logger::INFO)
      @force = false # Wether to force the task to execute
      super
    end

    ##
    # Return the set of all prequisite files
    ##
    def files(dir = nil)
      # If dir is provided we return a new file set
      return FileSet.new(Dir.glob(dir)) unless dir.nil?

      # In default case we return a set of output files of all dependant class
      @files ||=
        begin
          files = FileSet.new
          prerequisite_tasks.select { |t| t.is_a? Chore }.each do |t|
            files.merge(t.output_files)
          end
          files
        end
    end

    ##
    # Override execute to decorate the contex with self instance method
    def execute(args = nil)
      args ||= EMPTY_TASK_ARGS
      if application.options.dryrun
        application.trace "** Execute (dry run) #{name}"
        return
      end
      application.trace "** Execute #{name}" if application.options.trace
      application.enhance_with_matching_rule(name) if @actions.empty?

      # Instance exec decorate the context of the lambda with self methods
      @actions.each { |act| instance_exec(self, args, &act) }
    end

    ##
    # Since we are not executing with the normal context,
    # [1] will try the command [] which does not exist, we want it
    # to instead create a new array
    def [](index)
      Array.new([index])
    end

    ##
    # Return wether a single file changed in regard to this task
    ##
    def changed?(file)
      File.mtime(file) > @last_executed
    end

    def invoke_with_call_chain(*args)
      @succeeded = true
      super
      @logger.flush
      @metadata['last_executed'] = Time.now.to_i if @succeeded && needed?
      exit(1) unless @succeeded
    end

    ##
    # Override
    # Return wether the task need to be override
    def needed?
      needed = prerequisite_tasks.empty? || @force
      needed ||= prerequisite_tasks.any? do |t|
        (!t.is_a? Chore) || t.output_files.any? { |f| changed?(f) }
      end
      @logger.important(" Skipping task: #{name.capitalize.bold}") unless needed
      needed
    end
  end
end
