require 'rake/garden/command_args'

class String
  ##
  # Method that is set on a string to format it with file
  def format_with_file!
    unless self.frozen?
      self._format_with_file if self.respond_to? :_format_with_file
    end
    self
  end

  def >>(other)
    Args.new [self.format_with_file!], other.format_with_file!
  end
end
