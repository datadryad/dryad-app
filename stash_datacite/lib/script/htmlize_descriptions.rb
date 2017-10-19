require 'rails_rinku'
require 'nokogiri'
require 'cgi'

# usage example:
# require 'script/htmlize_descriptions'
#
# i = Script::HtmlizeDescriptions.new('my cat has fleas')
# i.html? # false
# i.text_as_html # "<p>my cat has fleas</p>"

module Script
  class HtmlizeDescriptions

    def initialize(text)
      @text = text
    end

    # indicates if it appears as though the text is already HTML or not CGI.escapeHTML makes entities which get introduced when stripping
    def html?
      return false if @text.blank?
      ActionController::Base.helpers.strip_tags(@text) != CGI.escapeHTML(@text)
    end

    def text_as_html
      display_br(@text)
    end

    private

    # these copied from helpers since too hard to get it to import

    # function to take a string and make it into html_safe string as paragraphs
    # expanded to also make html links, but really we should be doing this a different
    # way in the long term by having people enter html formatting and then displaying
    # what they actually want instead of guessing at things they typed and trying to
    # display magic html tags based on their textual, non-html.  We could strip it out if something hates html.
    def display_br(str)
      return nil if str.nil?

      my_str = link_urls(str)
      my_str = my_str.split(/(\r\n?|\n){2}/).reject(&:blank?)
      "<p>#{my_str.map { |i| i }.join('</p><p>')}</p>"
    end

    # kludge in some linking of random URLs they pooped into their text.
    def link_urls(my_str)
      # auto_link is part of rinku which gets added to ActionController
      out = ActionController::Base.helpers.auto_link(my_str, html: { target: '_blank' }) do |text|
        ActionController::Base.helpers.truncate(text, length: 60)
        # text.ellipsisize(80)
      end
      # We need to add the title attribute with the full URL so people can see the full url with hover on most browser if they like
      # unfortunately, rinku doesn't allow a dynamic title attribute to be easily added that is based on the href value, so Nokogiri
      doc = Nokogiri::HTML::DocumentFragment.parse(out)
      doc.css('a').each do |link|
        link['title'] = link.attributes['href'].value
      end
      doc.to_s
    end

  end
end
