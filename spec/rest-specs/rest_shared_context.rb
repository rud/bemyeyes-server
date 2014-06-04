shared_context "rest-context" do
 before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:9292"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:9292"

    @email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
    @password = AESCrypt.encrypt('Password1', @security_salt)
  end

  def create_user
  	createUser_url = "#{@servername_with_credentials}/users/"
  	 response = RestClient.post createUser_url, {'first_name' =>'first_name', 
         'last_name'=>'last_name', 'email'=> @email, 
         'role'=> 'helper', 'password'=> @password }.to_json

         jsn = JSON.parse response.body
         id = jsn['id']
         return id
  end
end
