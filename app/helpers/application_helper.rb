require 'kramdown'
require 'kramdown-parser-gfm'

module ApplicationHelper
  # reverses name and puts last, first middle, etc
  def name_reverser(name)
    return '[Name not set]' if name.blank?

    name_split = name.delete(',').split
    return name if name_split.length < 2

    "#{name_split.last} #{name_split[0..-2].join(' ')}"
  end

  def display_desc(description)
    fragment = Nokogiri::HTML5.fragment(description)
    tables = fragment.css('table')
    tables.wrap('<div class="table-wrapper" role="region" tabindex="0" aria-label="Table"></div>')
    fragment.to_html
  end

  def markdown_render(content)
    return '' if content.blank?

    # all html elements minus those in next comment
    esc_elements = %w[abbr address area article aside audio bdi bdo blockquote body br button
                      canvas caption cite col colgroup command datalistdd del details dfn div
                      dl dt embed fieldset figcaption figure footer form header html iframe
                      img input ins kbd keygen label legend main map mark menu meter nav object
                      optgroup option output p param progress q rp rt ruby s samp section
                      select small source span summary textarea timetr track u var video wbr
                      a b code em h1 h2 h3 h4 h5 h6 hr i li pre ol strong ul]
    # kept elements: sub sup table tbody td tfoot th thead

    content = CGI.escapeElement(content, esc_elements)

    Kramdown::Document.new(content, { input: 'GFM', header_offset: 1 }).to_html
  end

  def ldf_pricing_tiers_options
    FeeCalculator::BaseService::ESTIMATED_FILES_SIZE.map { |tier| ["#{filesize(tier[:range].max)} ($#{tier[:price]})", tier[:tier]] }
  end
end
