require_relative './rest_shared_context'

describe  "post event" do
  include_context "rest-context"
  it "can post event" do
    register_device
    user_id = create_user 'helper'
    token = log_user_in

    create_event_url  = "#{@servername_with_credentials}/stats/event"
    response = RestClient.post create_event_url, {'token_repr'=> token, 'event'=> 'share_on_twitter'}.to_json

    expect(response.code).to eq(200)
    user = User.first(:_id => user_id)
    expect(user.helper_points.count).to eq(2)
  end

  it "can only post an event once" do
    register_device
    user_id = create_user 'helper'
    token = log_user_in

    create_event_url  = "#{@servername_with_credentials}/stats/event"
    response = RestClient.post create_event_url, {'token_repr'=> token, 'event'=> 'share_on_twitter'}.to_json

    expect(response.code).to eq(200)

    expect{ RestClient.post create_event_url, {'token_repr'=> token, 'event'=> 'share_on_twitter'}.to_json}
    .to raise_error(RestClient::BadRequest)
  end
end

describe 'community endpoint' do
  include_context "rest-context"
  it 'shows stats' do
    get_community_stats_url = "#{@servername_with_credentials}/stats/community"
    response = RestClient.get get_community_stats_url, {:accept => :json}
    expect(response.code).to eq(200)

    expect(response).to match_response_schema("stat_community")
  end
end

describe 'profile endpoint' do
  include_context "rest-context"

  it 'needs token to auth' do
    get_profile_stats_url = "#{@servername_with_credentials}/stats/profile/no_token"

    expect{RestClient.get get_profile_stats_url, {:accept => :json}}
    .to raise_error(RestClient::BadRequest)
  end

  it 'returns valid json' do
    token = create_user_return_token
    get_profile_stats_url = "#{@servername_with_credentials}/stats/profile/#{token}"
    response = RestClient.get get_profile_stats_url, {:accept => :json}

    expect(response.code).to eq(200)
    expect(response).to match_response_schema("stat_profile")
  end

  describe "actionable tasks" do
    it "returns valid json" do
      token = create_user_return_token
      get_remaining_tasks_url = "#{@servername_with_credentials}/stats/actionable_tasks/#{token}"
      response = RestClient.get get_remaining_tasks_url, {:accept => :json}
      expect(response.code).to eq(200)
      expect(response).to match_response_schema("remaining_tasks")
    end
  end

  def create_user_return_token
    #create user
    create_user
    register_device
    token = log_user_in
    token
  end
end
