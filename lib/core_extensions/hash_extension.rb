module CoreExtensions
  module Hash
    # compacts a set of hashes/arrays recursively
    def recursive_compact
      helper_hash_compact(self)
    end

    def recursive_compact!
      clear.merge!(recursive_compact)
    end

    def diff(compare_to)
      reject { |k, v| compare_to[k] == v }
        .merge!(compare_to.reject { |k, _v| key?(k) })
    end

    private

    # something weird happens in here because objects don't match the Hash class and not even is_a? hash.
    # I have to create a new hash/array and see if the classes match to get this to work.  Yuck.
    def helper_hash_compact(hsh)
      hsh.each_with_object({}) do |(k, v), new_hash|
        next if v.nil? || ((v.instance_of?({}.class) || v.instance_of?([].class)) && v.empty?)

        new_hash[k] = (
          if v.instance_of?({}.class)
            helper_hash_compact(v)
          elsif v.instance_of?([].class)
            helper_array_compact(v)
          else
            v
          end
        )

      end
    end

    def helper_array_compact(arr)
      new_arr = arr.map do |i|
        if i.instance_of?([].class)
          helper_array_compact(i)
        elsif i.instance_of?({}.class)
          helper_hash_compact(i)
        else
          i
        end
      end
      new_arr.delete_if { |i| i.nil? || ([[].class, {}.class].include?(i.class) && i.empty?) }
    end

  end
end
