module FrictionlessHelper

  def expect_right_response(response)
    expect(response.status).to eql(200)
    response_body = JSON.parse(response.body)
    expect(response_body[0]['frictionless_report']['report']).to include('errors')
    expect(response_body[0]['frictionless_report']['status']).to eq('issues').or eq('error')
  end
end
