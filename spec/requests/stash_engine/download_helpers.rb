require 'json'

module DownloadHelpers
  RSpec.configure do |config|
    config.render_views = true
    config.include DownloadHelpers # include myself if required
  end

  def stub_202_status
    stub_request(:get, %r{/api/presign-obj-by-token/#{@token.token}.+})
      .to_return(status: 202, body:
            {  status: 202,
               token: @token.token,
               "cloud-content-byte": 4_393_274_895,
               message: 'Object is not ready' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def stub_200_status
    stub_request(:get, %r{/api/presign-obj-by-token/#{@token.token}.+})
      .to_return(status: 200, body:
            { status: 200,
              token: @token.token,
              "cloud-content-byte": 4_393_274_895,
              "url": ' https://uc3-s3mrt1001-stg.s3.us-west-2.amazonaws.com/6e6622f0-f4be-4f02-99c1-7fd81c0abd52/data?' \
                    'response-content-disposition=attachment%3B%20filename%3Ddoi_10.7959_dryad.q83bk3p1__v1.zip&' \
                    'response-content-type=application%2Fzip&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEDEaCXVzLXdlc3QtMiJHMEUC' \
                    'IQDqf9U%2BVaKsqOhRArmhmacuKtvAqBBdyYBfBxDTt74OTQIgB9F1Z904ZGa%2BGpfb5oTf%2BYskfWsoDJQgogjn43qpsjQqvQMI' \
                    'mf%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgw0NTE4MjY5MTQxNTciDAV95twwZRGVqEcrGiqRA%2Bx%2FhbJmLfpgBQtSYJcSrjo%' \
                    '2FtP8vVmanA3V6KvfjyZ2qos9%2FtemFlNsVLx9nMqjNa29nRyCkIZCnjTGoJBwL%2FWDBwmSb%2F%2BPWa5UCrFoLrUsYuMWDrgzh9' \
                    '3O3tXZEKB3a%2BIopo7NGAaMuR8SbFC%2F5z8Bc%2BdHevngDBfQ%2F8WN99w9%2Fq9vTiWcxco06fWRcnr%2FR2faoKFa7ohdtgjw5OZx2Dly' \
                    'ClIw0CFxTU8SFe9apEeXK5Pi6TVnvVx2coZt7BQU1YzrxDxVyeSL6SwkSCZqfwgxp15ZLKoG15R9puHPypQ1oBN0ojd6Qm8BzR5%2BsTtCv9N9J' \
                    'kfdQhpNXfeVJ32jiS35frGLimG4%2FqJfVpzte3fMWD1VQ3fCloHXJkG8%2FOyY9m7vKvLRIzhq4v7z8lPanJChn2zm7yzga4LRZ8m0YGqs3OjU' \
                    'Pw0HlsagL8ztJzGJIKWVocm7fUsCu8DIerHPDW2YzD0lxl17FABwn53xtG2mRuvgCBxWoJZg3TsOiu79Rt8FwEJtltWUM%2FPgt42ab3L9OMJKi5vY' \
                    'FOusB2MlzLLPDWM2pD77jvav3%2BW90xhrHDQ0J6fDGaSeInK2r0Dp%2B7XmsIWRe8iFZ6cAxJ8CxZEZwdmt5dch4c4%2F7VJI00R8c5Fx5LXXPphZ0' \
                    'mICl3YL7JdYnwVdxl274lxWsf4zLoIektvqOgFbhLbYjnPzDSUfmKGspNsMqeopGTJCLxyGZuv8vply7bhzNGettWh8sAq2oxb0fI5yr3pnq7C4uefDw' \
                    '2bf%2BffeN6pLpEnAiQHGeyQEgwWtFnMrSncaizq6hB5wWqqY6ll7oZFdvGY8Q09dyHisuY2UsayBVSwmNfiOZVdOs4ZtMSA%3D%3D&X-Amz-Algorithm' \
                    '=AWS4-HMAC-SHA256&X-Amz-Date=20200605T005008Z&X-Amz-SignedHeaders=host&X-Amz-Expires=14400&X-Amz-Credential=ASIAWSMX' \
                    '3SNWWJIVF5XY%2F20200605%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Signature=1ab5ce15d2687fa830a06303c299b004cc35' \
                    'e6ec28866c8e27eb72d6879ecc95',
              "message": 'Payload contains token info' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def stub_404_status
    stub_request(:get, %r{/api/presign-obj-by-token/#{@token.token}.+})
      .to_return(status: 404, body:
            {  status: 404,
               token: @token.token,
               "cloud-content-byte": 4_393_274_895,
               message: 'Not found' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def stub_404_assemble
    stub_request(:get, %r{/api/assemble-version/.+/1\?content=producer&format=zipunc})
      .to_return(status: 404, body: 'Internal server error', headers: {})
  end

  def stub_408_assemble
    stub_request(:get, %r{/api/assemble-version/.+/1\?content=producer&format=zipunc})
      .to_return(status: 408, body:
            {  status: 408,
               message: 'Timed out' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  def stub_408_status
    stub_request(:get, %r{/api/presign-obj-by-token/#{@token.token}.+})
      .to_return(status: 408, body:
            {  status: 408,
               message: 'Timed out' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

end
