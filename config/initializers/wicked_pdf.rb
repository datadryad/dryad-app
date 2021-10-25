# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

# this is a monkeypatch that fixes WickedPDF rendering in situations where another class overrides render, also.
# Geoblacklight 3.4 also overrides rendering and without patch then no page on the site will render at all.
# I found this at https://github.com/mileszs/wicked_pdf/pull/919/files#diff-15fe87701d185f1a00b4bdec59bbe86bea2079adb73d7235651102e21d6da578
# and it solves our problem.
#
# See also https://github.com/mileszs/wicked_pdf/issues/876 and https://github.com/mileszs/wicked_pdf/pull/919
class WickedPdf
  module PdfHelper
    def render(options = nil, *args, &block)
      if options.is_a?(Hash) && options.key?(:pdf)
        options[:basic_auth] = set_basic_auth(options)
        make_and_send_pdf(options.delete(:pdf), (WickedPdf.config || {}).merge(options))
      elsif respond_to?(:render_without_wicked_pdf)
        render_without_wicked_pdf(options, *args, &block)
      else
        super(options, *args, &block)
      end
    end

    def render_to_string(options = nil, *args, &block)
      render_to_string_with_wicked_pdf(options, *args, &block)
    end

    def render_with_wicked_pdf(options = nil, *args, &block)
      render(options, *args, &block)
    end
  end
end

WickedPdf.config = {
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # one of the wkhtmltopdf-binary family of gems.
  # exe_path: '/usr/local/bin/wkhtmltopdf',
  #   or
  # exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')

  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',

  # Using wkhtmltopdf without an X server can be achieved by enabling the
  # 'use_xvfb' flag. This will wrap all wkhtmltopdf commands around the
  # 'xvfb-run' command, in order to simulate an X server.
  #
  # use_xvfb: true,
}
