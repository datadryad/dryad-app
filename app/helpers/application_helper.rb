module ApplicationHelper
  # reverses name and puts last, first middle, etc
  def name_reverser(name)
    return '[Name not set]' if name.blank?

    name_split = name.delete(',').split
    return name if name_split.length < 2

    "#{name_split.last} #{name_split[0..-2].join(' ')}"
  end

  def markdown_render(content)
    @md_options = {
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: false,
      disable_indented_code_blocks: true,
      strikethrough: true,
      space_after_headers: true,
      underline: false,
      highlight: false,
      link_attributes: { rel: 'nofollow', target: '_blank' }
    }.freeze

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

    markdown = Redcarpet::Markdown.new(KnockDownHeadings.new(hard_wrap: true), @md_options)
    markdown.render(content).html_safe
  end

  class KnockDownHeadings < Redcarpet::Render::HTML
    def header(text, header_level)
      "<h#{header_level + 1}>#{text}</h#{header_level + 1}>"
    end
  end

end
