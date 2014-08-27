require_relative './rest_shared_context'


describe "smoketest" do
  include_context "rest-context"
  it "redirects from root" do
    url = @servername
    response = RestClient.get url

    #ok so this is not the most elegant way of testing the redirect - but its ok for now
    expect(response).to include("<title>Be My Eyes - crowdsourced help for the blind</title>")
  end
  it "can get the logs" do
    url = "#{@servername_with_credentials}/log/"
    response = RestClient.get url
    expect(response.code).to eq(200)
  end
end
