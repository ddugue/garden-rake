# frozen_string_literal: true

require 'rake'
require 'rake/task'
require 'rake/application'

require 'rake/garden/metadata'
require 'rake/garden/logger'
require 'rake/garden/fileset'
require 'rake/garden/filepath'

module Garden
  ##
  # A chore is a task you do not want to execute or to execute it as needed
  # It tries to evaluate wether it should be executed or not. It also
  # includes its own logging system. See the +Logger+ class for details
  class Chore < Rake::Task
    attr_reader :last_executed
    attr_accessor :options

    def initialize(task_name, app)
      @metadata = JSONMetadata.metadata.namespace(task_name)
      @last_executed = Time.at(@metadata.fetch('last_executed', 0) || 0)
      @logger = Logger.new(level: $LOGLEVEL || Logger::INFO)
      @force = false # Wether to force the task to execute
      super
    end

    ##
    # Represent the printable version of this task name
    def title
      name.capitalize.bold.sub('_', ' ')
    end

    ##
    # Represent the outputed files generated or modified by this chore
    def output_files
      @output_files ||= Fileset.new
    end

    ##
    # Iterate over output_files
    def each(&block)
      return enum_for(:each) unless block_given?
      output_files.each { |f| f.each(&block) }
    end

    ##
    # Return the files needed to execute this chore
    def input_files
      ts = prerequisite_tasks.select { |t| t.is_a? Chore }.to_a
      @input_files ||= Fileset.new(ts)
    end

    ##
    # Return a fileset
    # If +dir+ is non nil, return a glob based fileset
    # In any other case return input_files
    def files(dir = nil)
      return Fileset.from_glob(dir) unless dir.nil?
      input_files
    end

    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if [true, 'true'].include? prerequisite_name
        # If true, it is simply an hack to make the chore always execute
        # even when it has dependencies

        require 'rake/garden/noop_chore'

        @force = true
        NoopChore.new @application
      elsif Filepath.is_file? prerequisite_name
        # We convert filepath into FileChores
        require 'rake/garden/file_chore'

        FileChore.new(prerequisite_name, @application)
      else
        super prerequisite_name.to_s
      end
    end

    ##
    # Override execute to decorate the contex with self instance method
    def execute(args = nil)
      @args = args || EMPTY_TASK_ARGS
      return if application.options.dryrun
      application.enhance_with_matching_rule(name) if @actions.empty?
    end

    ##
    # Since we are not executing with the normal context,
    # [1] will try the command [] which does not exist, we want it
    # to instead create a new array
    def [](index)
      Array.new([index])
    end


    ##
    # We override the invoke command of rake to plug our own
    # logging
    def invoke_with_call_chain(*args)
      super
      @logger.flush
      exit(1) if respond_to?(:error?) && error?
    end

    class << self
      def define_task(options, *args, &block)
        chore = Rake.application.define_task(self, *args, &block)
        chore.options = options
        chore
      end
    end
  end

  ##
  # Set the log level
  # NONE = 0      # Output only errors
  # IMPORTANT = 1 # Output minimal information
  # INFO = 2      # Output all executed commands
  # VERBOSE = 3   # Output all stdout
  # DEBUG = 4     # Output garden debug information as well
  def setlog(level)
    $LOGLEVEL = level
  end
end
