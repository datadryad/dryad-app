module StashEngine
  module DownloadsHelper
    class SniffColSeparator
      DELIMITERS = [',', ';', "\t", '|', ':'].freeze

      def initialize(string:)
        @string = string
      end

      def self.find(string)
        new(string: string).find
      end

      def find
        # String empty
        return nil unless first

        # No separator found
        return nil unless valid?

        delimiters.first.first
      end

      private

      def valid?
        !delimiters.collect(&:last).reduce(:+).zero?
      end

      def delimiters
        @delimiters ||= DELIMITERS.inject({}, &count).sort(&most_found)
      end

      def most_found
        ->(a, b) { b[1] <=> a[1] }
      end

      def count
        ->(hash, delimiter) {
          hash[delimiter] = first.count(delimiter)
          hash
        }
      end

      def first
        @first ||= @string&.split("\n")&.first
      end
    end

    def merge(path, h, size)
      if path.size == 1
        h[path[0]] = size
      else
        h[path[0]] ||= {}
        merge(path[1..], h[path[0]], size)
      end
    end

    def create_tree(k, v)
      str = "<li class=\"#{v.is_a?(Hash) ? 'tree-folder' : 'tree-file'}\"><span class=\"tree-details\">"
      str += "<i class=\"#{v.is_a?(Hash) ? 'far fa-folder' : 'fas fa-file'}\" aria-hidden=\"true\"></i>#{k}"
      if v.is_a?(Hash)
        str += '</span><ul>'
        v.each { |key, val| str += create_tree(key, val) }
        str += '</ul>'
      else
        str += "<span class=\"tree-size\">#{filesize(v)}</span></span>"
      end
      str += '</li>'
    end

    def tree_view(file)
      h = {}
      paths = file.container_files.map(&:path).map { |path| path.split('/') }
      paths.each_with_index { |path, i| merge(path, h, file.container_files[i].size) }
      str = '<ul class="o-list file-tree">'
      h.each { |k, v| str += create_tree(k, v) }
      str += '</ul>'
    end
  end
end
