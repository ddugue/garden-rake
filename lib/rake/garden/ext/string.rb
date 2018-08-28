require 'rake/garden/command_args'

##
# Overriding Array class to provide helper for our dsl
class String
  ##
  # Method that is set on a string to format it with file
  def format_with_file!
    unless frozen?
      _format_with_file if respond_to? :_format_with_file
    end
    self
  end

  def >>(other)
    Args.new [format_with_file!], other.format_with_file!
  end
end
