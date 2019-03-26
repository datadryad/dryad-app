require 'spec_helper'
require 'stash/download/base'
require 'stash/streamer'
require 'ostruct'

# a base class for version and file downloads, providing some basic functions
module Stash
  module Download
    describe 'Base' do

      it 'initializes with a controller context object' do
        item = Base.new(controller_context: 'blah')
        expect(item.cc).to eql('blah')
      end

      describe '#stream_response' do

        before(:each) do

          # make controller context have response_body and response.headers[]
          @base = Base.new(controller_context: OpenStruct.new(response_body:  '',
                                                              response: OpenStruct.new(headers: {})))

          cli = double('client')

          head_response = OpenStruct.new(http_header:
                                             { 'Content-Type' => ['text/plain'],
                                               'Content-Length' => [37],
                                               'Content-Disposition' => ['inline; filename="blah.txt"'] })

          allow(cli).to receive(:head).with(anything, anything).and_return(head_response)

          my_http_client = double(Stash::Repo::HttpClient)

          allow(my_http_client).to receive(:client).and_return(cli)
          allow(Stash::Repo::HttpClient).to receive(:new).and_return(my_http_client)

          allow(Stash::Streamer).to receive(:new).with(anything, anything).and_return('This is my stream')
          allow_any_instance_of(Stash::Download::Base).to receive(:disposition_filename).and_return('12xu.zip')
        end

        it 'sets up Content-Type' do
          @base.stream_response(url: 'http://example.com', tenant: 'tenant would be a better object')
          expect(@base.cc.response.headers['Content-Type']).to eql('text/plain')
        end

        it 'sets up Content-Length' do
          @base.stream_response(url: 'http://example.com', tenant: 'tenant would be a better object')
          expect(@base.cc.response.headers['Content-Length']).to eql(37)
        end

        it 'sets up Content-Disposition' do
          @base.stream_response(url: 'http://example.com', tenant: 'tenant would be a better object')
          expect(@base.cc.response.headers['Content-Disposition']).to eql('12xu.zip')
        end

        it 'has correct response_body' do
          @base.stream_response(url: 'http://example.com', tenant: 'tenant would be a better object')
          expect(@base.cc.response_body).to eql('This is my stream')
        end

      end

      describe 'Base.log_warning_if_needed' do
        before(:each) do
          @logger_mock = double('Rails.logger').as_null_object
          @error = OpenStruct.new(class: 'TestClass', backtrace: %w[1 2 3 4])
          @resource = StashEngine::Resource.create
          allow(Rails).to receive(:env).and_return(OpenStruct.new('development?' => true))
        end

        it 'logs a message' do
          expect(Rails).to receive(:logger).and_return(@logger_mock)
          expect(@logger_mock).to receive(:warn)
          Base.log_warning_if_needed(error: @error, resource: @resource)
        end
      end
    end
  end
end
