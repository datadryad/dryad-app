module HelpHelper

  def account
    HELP_PAGES_ACCOUNT
  end

  def requirements
    HELP_PAGES_REQUIREMENTS
  end

  def guides
    HELP_PAGES_GUIDES
  end

  def submission_steps
    HELP_PAGES_STEPS
  end

  def expanded?(path)
    request.path == '/help' || request.path.include?(path)
  end

  def create_nav(path, label = nil)
    label ||= path.humanize

    "<span class=\"expand-button\"><button aria-controls=\"#{path}\" aria-expanded=\"#{expanded?(path)}\">#{label}</button></span>"
  end

  def create_menu(page_list)
    path = page_list[0][:path].split('/')[2]
    str = "<ul id=\"#{path}\"#{' hidden' unless expanded?(path)}>"
    page_list.each do |page|
      str += "<li><a href=\"#{page[:path]}\""
      str += ' aria-current="page"' if request.path == page[:path]
      str += ">#{page[:name]}"
      str += '<span class="pdfIcon" role="img" aria-label=" (PDF)"/></a>' if page[:path].end_with?('.pdf')
      str += '</a>'
      str += render template: page[:path], locals: { toc: true } if request.path == page[:path]
      str += '</li>'
    end
    str += '</ul>'
  end

end
