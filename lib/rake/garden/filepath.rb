
class FileAwareString
  attr_reader :file
  attr_reader :folder_root

  def initialize(folder_root, file, string)
    @string = string
    @file = file
    @folder_root = folder_root
    @formatted = false
  end

  def prefix
    @prefix ||=
      @folder_root ? @file.to_s.sub(@folder_root, '').sub(File.basename(@file), '') : ''
  end

  def format_string_with_file
    return @string if @formatted
    @formatted = true
    @string.gsub!(/%[bBfFnpxdDX]/) do |s|
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
  end

  def to_s
    format_string_with_file
  end
end
