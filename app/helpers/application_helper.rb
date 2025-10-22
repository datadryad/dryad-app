require 'commonmarker'

module ApplicationHelper

  def dupe_user_alert
    return false unless current_user&.email&.present?

    @email = current_user.email
    @existing_user = StashEngine::User.where(email: @email).where.not(id: current_user.id).first
    return true if @existing_user

    false
  end

  # reverses name and puts last, first middle, etc
  def name_reverser(name)
    return '[Name not set]' if name.blank?

    name_split = name.delete(',').split
    return name if name_split.length < 2

    "#{name_split.last} #{name_split[0..-2].join(' ')}"
  end

  def display_desc(description)
    fragment = Nokogiri::HTML5.fragment(description)
    dels = fragment.css('del')
    dels.add_class('from_md')
    anchors = fragment.css('a.anchor:empty')
    anchors.each(&:remove)
    links = fragment.css('a')
    links.each do |link|
      link.set_attribute('target', '_blank')
      link.add_child('<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i>')
    end
    tables = fragment.css('table')
    tables.wrap('<div class="table-wrapper" role="region" tabindex="0" aria-label="Table"></div>')
    fragment.to_html
  end

  def markdown_render(content:, header_offset: 0)
    doc = Commonmarker.parse(
      content, options: {
        render: { unsafe: true, escaped_char_spans: false },
        extension: { superscript: true, subscript: true }
      }
    )
    doc.walk do |node|
      node.header_level = node.header_level + header_offset if node.type == :heading
    end
    doc.to_html(plugins: { syntax_highlighter: { theme: '' } })
  end

  def readme_render(content)
    return '' if content.blank?

    # all html elements minus those in next comment
    esc_elements = %w[abbr address area article aside audio bdi bdo blockquote body button
                      canvas caption cite col colgroup command datalistdd del details dfn div
                      dl dt embed fieldset figcaption figure footer form header html iframe
                      img input ins kbd keygen label legend main map mark menu meter nav object
                      optgroup option output p param progress q rp rt ruby s samp section
                      select small source span summary textarea timetr track u var video wbr
                      a b code em h1 h2 h3 h4 h5 h6 hr i li pre ol strong ul]
    # kept elements: sub sup table tbody td tfoot th thead br

    content = CGI.escapeElement(content, esc_elements)

    markdown_render(content: content, header_offset: 1)
  end

  def ldf_pricing_tiers_options
    [['No limit', '']] + FeeCalculator::BaseService::ESTIMATED_FILES_SIZE.map do |tier|
      ["#{filesize(tier[:range].max)} ($#{tier[:price]})", tier[:tier]]
    end
  end
end
