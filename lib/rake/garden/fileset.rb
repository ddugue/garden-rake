require 'rake/garden/command_args'
require 'rake/garden/ext/string'

##
# Methods to work with our custom
module Garden
  def format_string_with_file(root, file, string)
    string.gsub!(/%[bBfFnpxdDX]/) do |s|
      prefix = file.to_s.sub(root, '').sub(File.basename(file), '')
      case s.to_s
      when '%f' then prefix + File.basename(file)
      when '%F' then File.basename(file)
      when '%b' then prefix + File.basename(file, '.*')
      when '%B' then File.basename(file, '.*')
      when '%x' then File.extname(file)
      when '%d' then prefix
      when '%D' then File.dirname(file)
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
  def with_file(root, file)
    String.send(:define_method, :_format_with_file) do
      format_string_with_file(root, file, self)
    end
    $CURRENT_FILE = file
    $CURRENT_ROOT = root
    yield file
    $CURRENT_FILE = nil
    $CURRENT_ROOT = nil
    remove_method_from_class(String, :_format_with_file)
  end

  ##
  # Class used to decorate the each method with our magic_format method
  ##
  class FileSet < Set
    GLOB = Regexp.new(/^[^\*]*/)

    def initialize(glob=nil)
      @filesets = []
      @pwd = Dir.pwd
      if glob.is_a? String
        @glob = glob
        super(Dir.glob glob)
      else
        super
      end
    end

    def join(sep)
      to_a.join sep
    end

    def glob
      @glob ||= ''
    end
    ##
    # Return the root of the glob pattern
    # For instance in src/**/* the root would be pwd + src
    def root
      @root ||= (GLOB.match(glob)[0] || '').to_s
    end
    ##
    # Fix to prevent ruby from memoizing magic_format when calling any?
    def any?
      super
      remove_method_from_class(String, :_format_with_file)
    end

    def each(&block)
      super do |f|
        with_file root, f, &block if File.file? f
      end
      @filesets.each do |fs|
        fs.each &block
      end
    end

    def anchor(fileset)
      @filesets.push(fileset)
    end

    def format_with_file!
      self
    end

    def >>(other)
      Args.new format_with_file!, other.format_with_file!
    end
  end
end
