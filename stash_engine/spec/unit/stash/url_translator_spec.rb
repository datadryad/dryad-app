require 'spec_helper'
require_relative '../../../lib/stash/url_translator'

module Stash

  describe :initialization do

    it 'sets the original_url' do
      translator = Stash::UrlTranslator.new('http://testing.example.org')
      expect(translator.original_url.present?).to eql(true)
    end

    it 'attributes are correct for Google Drive URLs' do
      translator = Stash::UrlTranslator.new('https://drive.google.com/file/d/0B9diV3DhsADzQ2Q2aDZGRFlkLVU/view?usp=sharing')
      expect(translator.service).to eql('google')
      expect(translator.direct_download).to eql('https://drive.google.com/uc?export=download&id=0B9diV3DhsADzQ2Q2aDZGRFlkLVU')
    end

    it 'sets the service to "google" for Google Docs URLs' do
      translator = Stash::UrlTranslator.new('https://docs.google.com/document/d/1vrQrKYAWVS9PeQHhOy9mcvDTvhgq85KCndScfrERHBk/edit?usp=sharing')
      expect(translator.service).to eql('google')
      expect(translator.direct_download).to eql('https://docs.google.com/document/d/1vrQrKYAWVS9PeQHhOy9mcvDTvhgq85KCndScfrERHBk/export?format=doc')
    end

    it 'sets the service to "google" for Google Presentations URLs' do
      translator = Stash::UrlTranslator.new('https://docs.google.com/presentation/d/1w_S-nfMOnIUob_QqkWkQ-FrbUdQm0tr6X-CqvqOu-yc/edit?usp=sharing')
      expect(translator.service).to eql('google')
      expect(translator.direct_download).to eql('https://docs.google.com/presentation/d/1w_S-nfMOnIUob_QqkWkQ-FrbUdQm0tr6X-CqvqOu-yc/export/pptx')
    end

    it 'sets the service to "google" for Google Sheets URLs' do
      translator = Stash::UrlTranslator.new('https://docs.google.com/spreadsheets/d/1wUMpgSivZyCxqHMpnlJ5uvNcgQY8XvH1_3WBH7kvXjE/edit?usp=sharing')
      expect(translator.service).to eql('google')
      expect(translator.direct_download).to eql('https://docs.google.com/spreadsheets/d/1wUMpgSivZyCxqHMpnlJ5uvNcgQY8XvH1_3WBH7kvXjE/export?format=xlsx')
    end

    it 'sets the service to "dropbox" for Dropbox URLs' do
      translator = Stash::UrlTranslator.new('https://www.dropbox.com/s/j84vdgcht1rxygb/generic_logo.svg?dl=0')
      expect(translator.service).to eql('dropbox')
      expect(translator.direct_download).to eql('https://dl.dropboxusercontent.com/s/j84vdgcht1rxygb/generic_logo.svg')
    end

    it 'sets the service to "box" for Box URLs' do
      translator = Stash::UrlTranslator.new('https://ucop.box.com/s/o39s94g28puss5ttt7vss8b0qrlge184')
      expect(translator.service).to eql('box')
      expect(translator.direct_download).to eql('https://ucop.box.com/public/static/o39s94g28puss5ttt7vss8b0qrlge184')
    end

  end

end
