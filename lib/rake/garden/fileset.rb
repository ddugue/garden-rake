require 'rake/garden/command_args'
require 'rake/garden/ext/string'

##
# Methods to work with our custom
module Garden
  def format_string_with_file(file, string)
    string.gsub!(/%[bfnpxdX]/) do |s|
      case s.to_s
      when '%f' then File.basename(file)
      when '%b' then File.basename(file, '.*')
      when '%x' then File.extname(file)
      when '%d' then File.dirname(file)
      when '%n' then file.pathmap('%n')
      when '%X' then file.pathmap('%X')
      when '%p' then file
      end
    end
  end

  ##
  # Safe remove a method from a class
  def remove_method_from_class(cls, method_name)
    return unless cls.method_defined? method_name
    cls.remove_method method_name
  end

  ##
  # Decorator function to allow string interpolation of filenames
  ##
  def with_file(file)
    String.send(:define_method, :_format_with_file) do
      format_string_with_file(file, self)
    end
    yield file

    remove_method_from_class(String, :_format_with_file)
  end

  ##
  # Class used to decorate the each method with our magic_format method
  ##
  class FileSet < Set
    ##
    # Fix to prevent ruby from memoizing magic_format when calling any?
    def any?
      super
      remove_method_from_class(String, :_format_with_file)
    end

    def each(&block)
      super do |f|
        with_file f, &block if File.file? f
      end
    end

    def format_with_file!
      self
    end

    def >>(other)
      Args.new format_with_file!, other.format_with_file!
    end
  end
end
