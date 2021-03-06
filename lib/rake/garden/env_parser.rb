# frozen_string_literal: true

module Garden
  ##
  # Module contains a single function +env+ to parse from ENV more intuitively
  module EnvParser
    # Returns a single value from ENV
    #
    # Make sure the key is case-insensitive, parse the data heuristically
    # * yes, y, true, on, True => true
    # * no, n, false, False => true
    # * numbers get converted to number
    # If the value is not present return :default
    def self.env(key, default: nil)
      hash = ENV.to_h.transform_keys { |k| k.to_s.downcase }
      key = key.downcase

      return default unless hash.include? key
      convert hash[key]
    end


    # Convert value based on heuristics
    def self.convert(value)
      case value.downcase
      when /^\d$/
        value.to_i
      when 'yes', 'true', 'on', 'y'
        true
      when 'no', 'false', 'off', 'n'
        false
      else
        value
      end
    end
    private_class_method :convert
  end
end
