

module Rake::Garden
  ##
  # Decorator function to allow string interpolation of filenames
  ##
  def with_file(f, &block)
    String.send(:define_method, :_format_with_file) do
      self.gsub! /%[bfnpxdX]/ do |s|
        case s.to_s
        when '%f'
          File.basename(f)
        when '%b'
          File.basename(f, '.*')
        when '%n'
          f.pathmap('%n')
        when '%x'
          File.extname(f)
        when '%d'
          File.dirname(f)
        when '%X'
          f.pathmap('%X')
        when '%p'
          f
        end
      end
    end
    block.call f
    String.remove_method(:_format_with_file) if String.method_defined? :_format_with_file
  end

  ##
  # Class used to decorate the each method with our magic_format method
  ##
  class FileSet < Set
    ##
    # Fix to prevent ruby from memoizing magic_format when calling any?
    def any?
      super
      String.remove_method(:_format_with_file) if String.method_defined? :_format_with_file
    end

    def each(&block)
      super do |f|
        with_file f, &block
      end
    end

    def format_with_file!
      self
    end

    def >>(other)
      ShArgs.new self.format_with_file!, other.format_with_file!
    end
  end
end

##
# Small data structure to pass Arguments to an SH Command
class ShArgs
  attr_reader :input
  attr_reader :command
  attr_reader :output

  def initialize(input, cmd)
    @input = input || nil
    @command = cmd
  end

  def >>(other)
    if other.is_a? String
      other = [other.format_with_file!]
    end
    @output = other
    self
  end
end

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
    ShArgs.new [self.format_with_file!], other.format_with_file!
  end
end

class Array
  def format_with_file!
    self.map(&:format_with_file!)
  end

  def >>(other)
    ShArgs.new self.format_with_file!, other.format_with_file!
  end
end

class File
  class << self
    def safe_mtime(f)
      File.exist?(f) ? File.mtime(f) : Time.at(0)
    end
  end
end
