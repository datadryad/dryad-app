require 'ostruct'

class OpenStruct
  def self_and_field_pairs
    each_pair.map { |field, _| [self, field] }
  end
end

class Hash
  # Converts a hash to an OpenStruct along with all its nested hashes. The hash
  # and all its sub-hashes become OpenStruct instances in the resulting
  # structure.

  # rubocop:disable all
  def to_ostruct
    top_ostruct = OpenStruct.new(self)
    stack = top_ostruct.self_and_field_pairs
    until stack.empty?
      ostruct, field = stack.pop
      case value = ostruct[field]
        when Hash
          ostruct[field] = sub_ostruct = OpenStruct.new(value)
          stack += sub_ostruct.self_and_field_pairs
        when Array
          # When the field is an array, iterate through all its elements
          # replacing all hashes with OpenStruct instances and push the new
          # structure's fields to the stack for nested inspection of hashes
          # later.
          value.each_with_index do |element, index|
            case element
              when Hash
                value[index] = sub_ostruct = OpenStruct.new(element)
                stack += sub_ostruct.self_and_field_pairs
            end
          end
      end
    end
    top_ostruct
  end
  # rubocop:enable all
end
