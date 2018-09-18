
class FileAwareString
  attr_reader :file
  attr_reader :folder_root

  def initialize(folder_root, file, string)
    @folder_root = folder_root
    @file = file
    @string = string

    # We keep the formatted attribute to make the conversion lazy and to
    # keep it happening more than once.
    @formatted = false
  end

  def prefix
    @prefix ||=
      @folder_root ? @file.to_s.sub(@folder_root, '').sub(File.basename(@file), '') : ''
  end

  def include?(other_string)
    @string.include? other_string
  end

  def format_string_with_file
    return @string if @formatted
    @formatted = true
    @string.gsub!(/%[bBfFpxdD]/) do |s|
      case s.to_s
      when '%f' then prefix + File.basename(@file)
      when '%F' then File.basename(@file)
      when '%b' then prefix + File.basename(@file, '.*')
      when '%B' then File.basename(@file, '.*')
      when '%x' then File.extname(@file)
      when '%d' then prefix.empty? ? "#{File.dirname(@file)}/" : prefix
      when '%D' then File.dirname(@file)
      when '%p' then @file
      end
    end
    return @string
  end

  def to_s
    format_string_with_file
  end

  def ==(other)
    return other == to_s if other.is_a? String
    return other.to_s == to_s if other.is_a? FileAwareString
    false
  end

  class << self
    attr_accessor :file
    attr_accessor :folder_root

    ##
    # Shortcut function to create a file aware string based on the current context
    def create(string)
      new(self.folder_root, self.file, string)
    end

    def [](string)
      create(string)
    end
  end
end
