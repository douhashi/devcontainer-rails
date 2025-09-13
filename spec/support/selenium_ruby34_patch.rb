# frozen_string_literal: true

# Monkey patch for Ruby 3.4.5 compatibility with unpack1
# Ruby 3.4.5 expects unpack1 to be called on a String, not on an Array
if RUBY_VERSION >= "3.4.0"
  class Array
    unless method_defined?(:unpack1)
      def unpack1(format)
        # For screenshot base64 data, we need to handle it properly
        if self.length == 1 && self.first.is_a?(String)
          self.first.unpack1(format)
        elsif self.is_a?(Array) && self.all? { |item| item.is_a?(String) }
          # Join the array and unpack
          self.join.unpack1(format)
        else
          raise ArgumentError, "unpack1 called on invalid array: #{self.inspect}"
        end
      end
    end
  end
end
