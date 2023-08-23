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
      autolink: true,
      no_intra_emphasis: true,
      tables: true,
      highlight: true,
      footnotes: true,
      link_attributes: { rel: 'nofollow', target: '_blank' }.freeze
    }.freeze

    return '' if content.blank?

    markdown = Redcarpet::Markdown.new(KnockDownHeadings, @md_options)
    markdown.render(content).html_safe
  end

  class KnockDownHeadings < Redcarpet::Render::HTML
    def header(text, header_level)
      "<h#{header_level + 1}>#{text}</h#{header_level + 1}>"
    end
  end

end
