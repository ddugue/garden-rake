require "rake/task.rb"
require "ostruct"
# require "rbtrace"

module Rake::Garden
  $test = OpenStruct.new
  class Chore < Rake::Task
    def lookup_prerequisite(prerequisite_name) # :nodoc:
      if prerequisite_name == true
        puts "Boolean"
        NoopChore.new('noop', @application)
      else
        super prerequisite_name.to_s
      end
    end

    def invoke_with_call_chain(*args)
      puts "Overriding in chore"
      super
    end

    def hello(text)
      n = self.name
      puts "Hello #{name} #{text}"
    end


    def execute(args=nil)
      args ||= EMPTY_TASK_ARGS
      if application.options.dryrun
        application.trace "** Execute (dry run) #{name}"
        return
      end
      application.trace "** Execute #{name}" if application.options.trace
      application.enhance_with_matching_rule(name) if @actions.empty?
      @actions.each { |act| self.instance_exec(self, args, &act) }
    end

    class << self
      def define_task(*args, &block)
        Rake.application.define_task(self, *args, &block)
      end
    end
  end

  class NoopChore < Chore
  end
end
