require_relative './rest_shared_context'

describe 'community endpoint' do
  include_context "rest-context"
  it 'shows stats' do
    get_community_stats_url = "#{@servername_with_credentials}/stats/community"
    response = RestClient.get get_community_stats_url, {:accept => :json}
    expect(response.code).to eq(200)

    jsn = JSON.parse response.body
    expect(jsn['blind']).to_not be_nil
    expect(jsn['helpers']).to_not be_nil
    expect(jsn['no_helped']).to_not be_nil
  end
end

describe 'profile endpoint' do
  include_context "rest-context"

  it 'needs token to auth' do
    get_profile_stats_url = "#{@servername_with_credentials}/stats/profile/no_token"
    
     expect{RestClient.get get_profile_stats_url, {:accept => :json}}
    .to raise_error(RestClient::BadRequest)
  end

  it 'shows no of blind helped' do
    token = create_user_return_token
    get_profile_stats_url = "#{@servername_with_credentials}/stats/profile/#{token}"
    response = RestClient.get get_profile_stats_url, {:accept => :json}
    expect(response.code).to eq(200)

    jsn = JSON.parse response.body
    expect(jsn['no_helped']).to_not be_nil
    expect(jsn['total_points']).to_not be_nil
    expect(jsn['events']).to_not be_nil
    expect(jsn['current_level']).to_not be_nil
    expect(jsn['next_level']).to_not be_nil

  end

  def create_user_return_token
     #create user
      create_user
      register_device
      token = log_user_in
      token
  end

end
