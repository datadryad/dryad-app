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

    markdown = Redcarpet::Markdown.new(KnockDownHeadings.new(hard_wrap: true), @md_options)
    markdown.render(content).html_safe
  end

  class KnockDownHeadings < Redcarpet::Render::HTML
    def header(text, header_level)
      "<h#{header_level + 1}>#{text}</h#{header_level + 1}>"
    end
  end

end
