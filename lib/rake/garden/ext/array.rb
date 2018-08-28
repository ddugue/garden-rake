require 'rake/garden/command_args'

##
# Overriding Array class to provide helper for our dsl
class Array
  def format_with_file!
    map(&:format_with_file!)
  end

  def >>(other)
    Args.new format_with_file!, other.format_with_file!
  end
end
