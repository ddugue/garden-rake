
module Rake::Garden
  ##
  # Proxy for Dir Glob that decorates string with
  # a magic format method
  ##
  def directories(path, &block)
    Dir.glob(path).each do |f|
      String.send(:define_method, :magic_format) do
        self.gsub! /%[fnpxdX]/ do |s|
          case s.to_s
          when '%f'
            File.basename(f)
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
    end
  end
end
