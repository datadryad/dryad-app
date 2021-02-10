require 'aws-sdk-s3'

# use example
# require 'stash/s3'
# s3 = Stash::S3.new
#
# s3.upload(directory: 'test01', file_path: '/Users/sfisher/Downloads/zuntitled/random_stuff/color1_03.png',
#           content_type: 'image/jpeg')
#
# s3.download(directory: 'test01', filename: 'color1_03.png', save_path: '/Users/sfisher/')
#
# s3.exists?(directory: 'test01', filename: 'color1_03.png')
#
# s3.info(directory: 'test01', filename:)
#
# s3.presigned_download_url(directory: 'test01', filename: 'color1_03.png', expires_in: 3600)
#
# s3.destroy(directory: 'test01', filename: 'color1_03.png')
#
# s3.presigned_upload_url(directory: 'test01', filename: 'color1_03.png', content_type: 'image/png', expires_in: 3600)
# Now upload your file using this curl command:
# curl -X PUT -T <file-path> -L "<some-url>"
#
# s3.multipart_upload(directory: 'test01', filename: '200m_file.gib', content_type: 'application/octet-stream', expires_in: 3600)

module Stash
  class S3
    def initialize
      # setting up basics
      @bucket_name = APP_CONFIG[:s3][:bucket]
      s3_credentials = Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
      @s3_client = Aws::S3::Client.new(region: APP_CONFIG[:s3][:region], credentials: s3_credentials)
      @s3_resource = Aws::S3::Resource.new(client: @s3_client)
    end

    def upload(directory: 'test01', file_path:, content_type:)
      file_name = File.basename(file_path)

      # s3 action
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{file_name}")
      # obj.upload_file(file_path, metadata: { content_type: content_type} )
      obj.upload_file(file_path, content_type: content_type )
    end

    def download(directory: 'test01', filename:, save_path:)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      obj.get(response_target: File.join(save_path, filename))
    end

    def destroy(directory: 'test01', filename:)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      obj.delete
    end

    def exists?(directory: 'test01', filename:)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      obj.exists?
    end

    def presigned_download_url(directory: 'test01', filename:, expires_in: 3600)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      obj.presigned_url(:get, expires_in: expires_in)
    end

    def info(directory: 'test01', filename:)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      # for normal objects in amazon, the etag is the md5
      # For items uploaded as multipart, then this isn't the case and they've baked their own thing.
      # https://stackoverflow.com/questions/6591047/etag-definition-changed-in-amazon-s3/31086810
      # A solution seems to be to use their wacky digest.  For multipart objects it is An MD5 of the MD5s of all parts
      # concatenated together followed by a dash and number of parts.  Uggh.

      # also why does the md5 have double quotes inside the string that I need to remove.  WTF, amazon?
      { size: obj.size, md5: obj.etag.gsub('"', '') }.with_indifferent_access
    end

    # this works for normal sizes < 5GB that don't need to be split into multipart
    def presigned_upload_url(directory: 'test01', filename:, content_type:, expires_in: 3600)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")
      url = obj.presigned_url(:put, expires_in: expires_in, content_type: content_type)
      puts <<~EOS
        Now upload your file using this curl command:
        curl -X PUT -T #{filename} -H "Content-Type: #{content_type}" -L "#{url}"
      EOS
    end

    def multipart_upload(directory: 'test01', file_path:, content_type:, expires_in: 3600)
      file_name = File.basename(file_path)

      # create multipart upload
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{file_name}")
      mpu = obj.initiate_multipart_upload(content_type: content_type)

      # write chunks
      chunk_size = File.size(file_path) / 2 + 1
      counter = 0
      parts = []
      open(file_path) do |f|
        while part = f.read(chunk_size)
          counter += 1
          @s3_client.upload_part(body: part, bucket: @bucket_name, key: mpu.object_key, upload_id: mpu.id, part_number: counter)
          # mpu.upload_part(data: part, part_number: counter)) # this doesn't work because they made their API more crappy in v3
          # IO.write("#{file_path}part#{counter}", part)
        end
      end


      # now must complete or abort multipart upload
      mpu.complete(compute_parts: true)
    end

    def info_explore(directory: 'test01', filename:, save_path:)
      obj = @s3_resource.bucket(@bucket_name).object("#{directory}/#{filename}")


      byebug
      # obj.content_length
      # 247069

      # obj.etag
      # "\"e903113b3e4a57672eb5d6b3a48010da\""

      # obj.content_encoding
      # nil

      # obj.content_type
      # ""

      # see the #copy_from for copying files or multipart

      # obj.delete({}) # the hash is mostly for permissions or versioning

      # obj.exists?({})

      # obj.get({}) and can take a block, some useful options are range

      # #initiate_multipart_upload(options = {}) ⇒ MultipartUpload

      # metadata the hash of metadata to get from s3

      # presigned_post({}) # options like content_type, content_disposition, content_encoding, expires,
      # success_action_redirect, success_action_status, website_redirect_location

      # presigned_url(http_method, params) => String
      # examples:
      #   obj.presigned_url(:get, expires_in: 3600)
      #
      # upload_file(source, options) {|response| } # automatically uses amazon multipart APIs for large files
      # Can provide callback to monitor progress of the upload

      # upload_stream(options, &block) #uploads a stream to S3, passed chunks automatically uploaded in parallel
      # obj.upload_stream do |write_stream|
      #   10.times { write_stream << 'foo' }
      # end

      # wait_until_exists
      # wait_until_not_exists
    end
  end
end
