module FilesHelper

  def download_file_name_link(file, params)
    file_name = file.download_filename.ellipsisize(200)
    return "<span><i class='fas fa-cancel' role='img' aria-label='Deleted' title='Deleted'></i> #{file_name}</span>".html_safe if file.file_deleted_at

    link_to download_stream_path(params), target: '_blank', class: 'js-individual-dl' do
      "<i class='fas fa-download' role='img' aria-label='Download'></i>#{file_name}".html_safe
    end
  end
end
