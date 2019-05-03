module Stash
  class UrlTranslator
    # a class to translate URLs to direct download links for cloud services.

    # test links
    # google_drive_file: https://drive.google.com/file/d/0B9diV3DhsADzQ2Q2aDZGRFlkLVU/view?usp=sharing
    # google_drive_open: https://drive.google.com/open?id=1P2lVY_NvGipGLYamQcxWcYe4mABha-3w
    # google_doc: https://docs.google.com/document/d/1vrQrKYAWVS9PeQHhOy9mcvDTvhgq85KCndScfrERHBk/edit?usp=sharing
    # google_presentation: https://docs.google.com/presentation/d/1w_S-nfMOnIUob_QqkWkQ-FrbUdQm0tr6X-CqvqOu-yc/edit?usp=sharing
    # google_sheet: https://docs.google.com/spreadsheets/d/1wUMpgSivZyCxqHMpnlJ5uvNcgQY8XvH1_3WBH7kvXjE/edit?usp=sharing
    # dropbox: https://www.dropbox.com/s/j84vdgcht1rxygb/generic_logo.svg?dl=0
    # box: https://ucop.box.com/s/o39s94g28puss5ttt7vss8b0qrlge184
    # non-mapped: http://www.koalastothemax.com/

    GOOGLE_DRIVE_FILE = %r{^https://drive\.google\.com/file/d/(\S+)/(?:view|edit)(?:\?usp=sharing)?$}
    GOOGLE_DRIVE_OPEN = %r{^https://drive\.google\.com/open\?id=(\S+)$}
    GOOGLE_DOC = %r{^https://docs\.google\.com/document/d/(\S+)/edit(?:\?usp=sharing)?$}
    GOOGLE_PRESENTATION = %r{^https://docs\.google\.com/presentation/d/(\S+)/edit(?:\?usp=sharing)?$}
    GOOGLE_SHEET = %r{^https://docs\.google\.com/spreadsheets/d/(\S+)/edit(?:\?usp=sharing)?$}
    DROPBOX = %r{^https://www\.dropbox\.com/s/(\S+)/([^/]+)(?:\?dl=[0-9]+)$}
    BOX = %r{^https://([^/]+box\.com)/s/(\S+)$}

    attr_reader :service, :direct_download, :original_url

    def initialize(original_url)
      u = URI(original_url)
      @original_url = (u.fragment ? original_url[0..-(u.fragment.length + 2)] : original_url)
      @service = nil

      %w[google_drive_file google_drive_open google_doc google_presentation google_sheet dropbox box].each do |m|
        next unless (@direct_download = send(m))
        @service = m
        @service = 'google' if m.start_with?('google')
        break
      end
    end

    private

    # these returns are supposed to be assignment, and not equality (==) because I want to check and assign at once
    def google_drive_file
      return nil unless (GOOGLE_DRIVE_FILE.match(@original_url))
      # "https://drive.google.com/uc?export=download&id=#{m[1]}"
      @original_url
    end

    def google_drive_open
      return nil unless (GOOGLE_DRIVE_OPEN.match(@original_url))
      @original_url
    end

    def google_doc
      return nil unless (m = GOOGLE_DOC.match(@original_url))
      "https://docs.google.com/document/d/#{m[1]}/export?format=doc"
    end

    def google_presentation
      return nil unless (m = GOOGLE_PRESENTATION.match(@original_url))
      "https://docs.google.com/presentation/d/#{m[1]}/export/pptx"
    end

    def google_sheet
      return nil unless (m = GOOGLE_SHEET.match(@original_url))
      "https://docs.google.com/spreadsheets/d/#{m[1]}/export?format=xlsx"
    end

    def dropbox
      return nil unless (m = DROPBOX.match(@original_url))
      "https://dl.dropboxusercontent.com/s/#{m[1]}/#{m[2]}"
    end

    def box
      return nil unless (m = BOX.match(@original_url))
      "https://#{m[1]}/public/static/#{m[2]}"
    end

  end
end
