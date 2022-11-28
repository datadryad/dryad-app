module StashEngine
  module LinkGenerator

    def self.create_link(type:, value:)
      # get [link_text, href] back from the id so we can create normal <a href link>
      send(type.downcase, value)
    end

    # This *should* only be called from #create_link, and if we reach it,
    # it's because the identifier type is one that we didn't know how to handle,
    # in which case we just return the identifier as-is.
    def self.method_missing(_method_name, *arguments)
      arguments.first
    end

    # (see #method_missing)
    def self.respond_to_missing?(*_args)
      true
    end

    # all these return [link_text, url]
    def self.doi(value)
      # example reference: doi:10.5061/DRYAD.VN88Q
      # example url: http://doi.org/10.5061/DRYAD.VN88Q
      item = Fixolator.new(id_value: value, target_prefix: 'doi:', resolver_prefix: 'https://doi.org/').text_and_link
      [item[1], item[1]]
    end

    def self.ark(value)
      # example reference: ark:/13030/m55d9m2t
      # example url: http://n2t.net/ark:/13030/m55d9m2t
      Fixolator.new(id_value: value, target_prefix: 'ark:/', resolver_prefix: 'http://n2t.net/ark:/').text_and_link
    end

    def self.arxiv(value)
      # info at https://arxiv.org/help/arxiv_identifier
      # example reference: arXiv:1212.4795
      # example url: https://arxiv.org/abs/1212.4795
      Fixolator.new(id_value: value, target_prefix: 'arXiv:', resolver_prefix: 'https://arxiv.org/abs/').text_and_link
    end

    def self.handle(value)
      # handle urls look like http://hdl.handle.net/2027.42/67268 sometimes.  Also hdl:1839/00-0000-0000-0009-3C7E-F
      # it seems like they do not represent them like handle:/2027/67268 or anything that I can find, but as full urls
      # in the citations I'm seeing
      Fixolator.new(id_value: value, target_prefix: 'hdl:', resolver_prefix: 'https://hdl.handle.net/').text_and_link
    end

    def self.isbn(value)
      # ISBNs are just numbers with maybe dashes in them (or spaces?)
      # a url like this seems to return results for isbns from worldcat. http://www.worldcat.org/search?q=bn%3A0142000280
      Fixolator.new(id_value: value, target_prefix: 'ISBN: ', resolver_prefix: 'http://www.worldcat.org/search?q=bn%3A').text_and_link
    end

    def self.pmid(value)
      # pubmed id references look like PMID: 19386008
      # the urls look like https://www.ncbi.nlm.nih.gov/pubmed/19386008
      Fixolator.new(id_value: value, target_prefix: 'PMID: ', resolver_prefix: 'https://www.ncbi.nlm.nih.gov/pubmed/').text_and_link
    end

    def self.purl(value)
      # it seems like PURLs are essentially just URLs that resolve to something else, so something like
      # http://purl.org/net/ea/cleath/docs/cat/

      value = "http://#{value}" unless value.strip.start_with?('http')
      [value, value]
    end

    def self.url(value)
      # I think people should be able to put them in correctly by copy/pasting, but maybe
      # people leave off the http(s) sometimes?

      value = "http://#{value}" unless value.nil? || value.strip.start_with?('http')
      [value, value]
    end

    def self.urn(value)
      # a urn could be a url or other things that may resolve or not resolve.  Just pass it on through.
      value
    end

    # A standard fixing and extracting class to get parts of many identifiers.
    # The goal is to take link text and identifier values and break the identifier values into parts
    # so that we can separate something like like doi:10.5061/DRYAD.VN88Q into
    # 1) identifier prefix and 2) bare identifier itself.  In the example above, 1) is doi: , 2) is 10.5061/DRYAD.VN88Q

    # if the item is really a url for resolution (starting with http) then we need to know that, also.
    class Fixolator
      # id_value would be something that the user typed in and may be full of garbage
      # target_prefix is what we know the generally used prefix should be when it's written
      # usually as a reference such as doi: or ark:/
      def initialize(id_value:, target_prefix:, resolver_prefix:)
        @id_value = id_value
        @target_prefix = target_prefix
        @resolver_prefix = resolver_prefix
        if id_value.nil?
          @is_http_url = false
          @prefix_correct = false
        else
          @is_http_url = id_value.strip.downcase.start_with?('http')
          @prefix_correct = id_value.strip.downcase.start_with?(target_prefix.strip.downcase)
        end
      end

      def http_url?
        @is_http_url
      end

      def prefix_correct?
        @prefix_correct
      end

      def reference_form
        return @id_value if http_url?

        "#{@target_prefix}#{bare_id}"
      end

      def bare_id
        if prefix_correct?
          # remove the prefix and give bare id
          @id_value[@target_prefix.strip.length..].strip
        else
          # they must've given it as a bare id if it didn't have the prefix (and isn't a URL)
          @id_value&.strip
        end
      end

      # returns text and link for creating a URL
      def text_and_link
        return [@id_value, @id_value] if http_url?

        [reference_form, "#{@resolver_prefix}#{bare_id}"]
      end
    end
  end

end
