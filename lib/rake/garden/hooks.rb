module Rake::Garden

  application = Rake.application
  $original_method = application.method(:invoke_task)

  def application.invoke_task(task_string)
    puts "Hooked to invoke_task"
    $original_method.(task_string)
  end
  def application.define_task(task_class, *args, &block) # :nodoc:
      task_name, arg_names, deps = resolve_args(args)

      original_scope = @scope
      if String === task_name and
         not task_class.ancestors.include? Rake::FileTask
        task_name, *definition_scope = *(task_name.split(":").reverse)
        @scope = Scope.make(*(definition_scope + @scope.to_a))
      end

      task_name = task_class.scope_name(@scope, task_name)
      deps = [deps] unless deps.respond_to?(:to_ary)
      if not task_class.ancestors.include? Chore
        deps = deps.map { |d| Rake.from_pathname(d).to_s }
      end
      task = intern(task_class, task_name)
      task.set_arg_names(arg_names) unless arg_names.empty?
      if Rake::TaskManager.record_task_metadata
        add_location(task)
        task.add_description(get_description(task))
      end
      task.enhance(deps, &block)
  ensure
    @scope = original_scope
  end
end
