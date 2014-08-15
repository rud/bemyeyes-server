require_relative './rest_shared_context'

describe "helper points" do
  include_context "rest-context"
  it "can get helper points" do
    email =  "user_#{(Time.now.to_f*100000).to_s}@example.com"
    password = AESCrypt.encrypt('Password1', @security_salt)
    createUser_url = "#{@servername_with_credentials}/users/"
    response = RestClient.post createUser_url, {'first_name' =>'first_name',
                                                'last_name'=>'last_name', 'email'=> email,
                                                'role'=> 'helper', 'password'=> password }.to_json

    jsn = JSON.parse response.body
    id = jsn['id']

    url = "#{@servername_with_credentials}/users/helper_points/" + id
    response = RestClient.get url, {:accept => :json}
    expect(response.code).to eq(200)

    url = "#{@servername_with_credentials}/users/helper_points_sum/" + id
    response = RestClient.get url, {:accept => :json}
    expect(response.code).to eq(200)

    jsn = JSON.parse response.body
    sum = jsn['sum']

    expect(sum).to eq(50)
  end
end
