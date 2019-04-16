module Stash
  module Import
    class DryadManuscript

      def initialize(resource:, httparty_response:)
        @resource = resource
        @response = httparty_response.with_indifferent_access # so you can use symbols instead of strings for access
      end

      def populate
        populate_title
        populate_authors
      end

      def populate_title
        @resource.update(title: @response[:title])
      end

      def populate_authors
        return if @response[:authors].blank? || @response[:authors][:author].blank?
        authors = @response[:authors][:author]
        authors.each do |api_author|
          author = @resource.authors.create(
              author_first_name: api_author['givenNames'],
              author_last_name: api_author['familyName'],
              author_orcid: (api_author['identifierType'] == 'orcid' ? api_author[:identifier] : nil)
          )
          update_email(db_author: author)
        end
      end

      # the 'correspondingAuthor' may be able to give us one of the authors email addresses, but not for most
      def update_email(db_author:)
        return if @response['correspondingAuthor'].blank? || @response['correspondingAuthor']['author'].blank? ||
            @response['correspondingAuthor']['email'].blank?

        return unless db_author.author_first_name == @response['correspondingAuthor']['author']['givenNames'] &&
            db_author.author_last_name == @response['correspondingAuthor']['author']['familyName']

        email = @response['correspondingAuthor']['email']

        # Some emails have a bunch of crap crammed in like "schirmel@uni-landau.de Contact Institution: University of Koblenz-Landau",
        # but it's not really always, so trying to extract an email with a regular expression if one is lying around in the junk somewhere.
        email = email.match(/\S+@\S+\.{1}\S+/).to_s
        return if email.blank?
        db_author.update(author_email: email)
      end
    end
  end
end
