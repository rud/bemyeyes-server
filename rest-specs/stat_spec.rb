require_relative './rest_shared_context'

describe 'community endpoint' do
   include_context "rest-context"
  it 'shows stats' do
    getCommunity_stats_url = "#{@servername}/stats/community" 
    puts getCommunity_stats_url
      response = RestClient.get getCommunity_stats_url, {:accept => :json}
      expect(response.code).to eq(200) 

      jsn = JSON.parse response.body
      expect(jsn['blind']).to_not be_nil
      expect(jsn['helpers']).to_not be_nil
      expect(jsn['no_helped']).to_not be_nil

  end  
end