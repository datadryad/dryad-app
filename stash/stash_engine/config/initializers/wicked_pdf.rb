# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.config = {
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # one of the wkhtmltopdf-binary family of gems.
  # exe_path: '/usr/local/bin/wkhtmltopdf',
  #   or
  # exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')

  # We tried using the whkthmltopdf-binary but it causes errors for NFS mounts in the logs which
  # make Debra annoyed.  We updated to 0.12.4 and it changed a kalyptorisk mount to a sysadmin mount instead. :-(
  # We believe it's being put in somehow by a compiler/linker and the configuration the precompiled binary used.
  # We might try to compile ourselves in the future but it requires 1.2G free space and QT and some other hairy
  # requirements to compile and who knows how long it would take to get the compilation correct.

  # exe_path: '/apps/dash2/local/bin/wkhtmltopdf'

  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  # layout: 'pdf.html',
}
