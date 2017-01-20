module StashEngine
  module LinkGenerator

    def create_link(type:, value: )

      # get [link_text, href] back from the id so we can create normal <a href link>

    end

    # all these return [link_text, url]
    def self.doi(value)
      # example reference: doi:10.5061/DRYAD.VN88Q
      # example url: http://doi.org/10.5061/DRYAD.VN88Q

      f = Fixolator.new(id_value: value, target_prefix: 'doi:')
      return [value, value] if f.is_url?

      [f.reference_form, "https://doi.org/#{f.bare_id}"]
    end

    def self.ark(value)
      # example reference: ark:/13030/m55d9m2t
      # example url: http://n2t.net/ark:/13030/m55d9m2t

      f = Fixolator.new(id_value: value, target_prefix: 'ark:/')
      return [value, value] if f.is_url?

      [f.reference_form, "http://n2t.net/ark:/#{f.bare_id}"]
    end

    def self.arxiv(value)
      # info at https://arxiv.org/help/arxiv_identifier
      # example reference: arXiv:1212.4795
      # example url: https://arxiv.org/abs/1212.4795

      link_text = "arXiv:#{link_text}" if link_text == value
      [link_text, "https://arxiv.org/abs/#{value}"]
    end

    def self.handle(value)
      # handle urls look like http://hdl.handle.net/2027.42/67268
      # it seems like they do not represent them like handle:/2027/67268 or anything that I can find, but as full urls
      # in the citations I'm seeing

      value = "http://hdl.handle.net/#{value.strip}" unless value.strip.start_with?('http')
      [link_text, value]
    end

    def self.isbn(value)
      # ISBNs are just numbers with maybe dashes in them (or spaces?)
      # a url like this seems to return results for isbns from worldcat. http://www.worldcat.org/search?q=bn%3A0142000280

      return [link_text, value] if value.strip.start_with?('http')
      [link_text, "http://www.worldcat.org/search?q=bn%3A#{value}"]
    end

    def self.pmid(value)
      # pubmed id references look like PMID: 19386008
      # the urls look like https://www.ncbi.nlm.nih.gov/pubmed/19386008

      link_text = "PMID: #{link_text}" if link_text == value
      [link_text, "https://www.ncbi.nlm.nih.gov/pubmed/#{value}"]
    end

    def self.purl(value)
      # it seems like PURLs are essentially just URLs that resolve to something else, so something like
      # http://purl.org/net/ea/cleath/docs/cat/

      value = "http://#{value}" unless value.strip.start_with?('http')
      [link_text, value]
    end

    def self.url(value)
      # a url is a very common thing and everyone should be able to put them in correctly by copy/pasting, but maybe
      # people leave off the http(s) sometimes?

      [link_text, value]
    end

    def self.urn(value)
      # a urn could be a url or other things that may resolve or not resolve.  Just pass it on through.

      [link_text, value]
    end

    # A standard fixing and extracting class to get parts of many identifiers.
    # The goal is to take link text and identifier values and break the identifier values into parts
    # so that we can separate something like like doi:10.5061/DRYAD.VN88Q into
    # 1) identifier prefix and 2) bare identifier itself.  In the example above, 1) is doi: , 2) is 10.5061/DRYAD.VN88Q

    # if the item is really a url for resolution (starting with http) then we need to know that, also.
    class Fixolator
      # id_value would be something that the user typed in and may be full of garbage
      # prefix is what we know the prefix should be based on the ID type from outsied this class
      def initialize(id_value:, target_prefix:)
        @id_value = id_value
        @target_prefix = target_prefix
        @is_url = id_value.strip.downcase.start_with?('http')
        @has_correct_prefix = id_value.strip.downcase.start_with?(target_prefix.strip.downcase)
      end

      def is_url?
        @is_url
      end

      def has_correct_prefix?
        @has_correct_prefix
      end

      def reference_form
        return @id_value if is_url?
        "#{@target_prefix}#{bare_id}"
      end

      def bare_id
        if has_correct_prefix?
          #remove the prefix and give bare id
          @id_value[@target_prefix.length..-1]
        else
          #they must've given it as a bare id if it didn't have the prefix (and isn't a URL)
          @id_value
        end
      end
    end
  end

end