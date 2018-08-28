require 'time'

class File
  class << self
    def safe_mtime(f)
      exist?(f) ? mtime(f) : Time.at(0)
    end
  end
end
