shared_context "rest-context" do
 before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:9292"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:9292"
  end
end
