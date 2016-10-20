require 'redcarpet'

# module
module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    @md_options ||= {
      autolink: true,
      underline: true,
      no_intra_emphasis: true,
      tables: true,
      highlight: true,
      footnotes: true,
      link_attributes: {rel: 'nofollow', target: "_blank"}
    }

    compiled_source = erb.call(template)
    renderer = if template.locals.include?('toc')
                 'Redcarpet::Render::HTML_TOC'
               else
                 'Redcarpet::Render::HTML.new(with_toc_data: true)'
               end
    "Redcarpet::Markdown.new(#{renderer}, #{@md_options} )."\
    "render(begin;#{compiled_source};end).html_safe"
  end
end
