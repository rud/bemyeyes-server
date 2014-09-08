require_relative './rest_shared_context'

describe "device update" do
  include_context "rest-context"
  UPDATEDMODEL = 'update_model'

  before(:each) do
    Device.destroy_all
  end

  def  update_device token, device_token = 'device_token', new_device_token = 'new_device_token'
    url = "#{@servername_with_credentials}/devices/update"
    response = RestClient.post url, {'token' =>token,
                                     'device_token'=> device_token, 'new_device_token' => new_device_token, 'device_name'=> 'device_name',
                                     'model'=> UPDATEDMODEL, 'system_version' => 'system_version',
                                     'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
                                     'locale'=> 'locale', 'development' => 'true'}.to_json
    expect(response.code).to eq(200)
    json = JSON.parse(response.body)
    json["token"]
  end
  it "can update a device" do
    create_user
    token = register_device
    update_device token

    expect(Device.where(:model => UPDATEDMODEL).count).to eq(1)
  end

  it "can update a device with a new device_token" do
    temp_device_token = "temp_device_token"
    new_device_token = "new_device_token"
    token = create_user
    register_device temp_device_token
    update_device token, temp_device_token, new_device_token

    expect(Device.where(:device_token => new_device_token).count).to eq(1)
    expect(Device.where(:device_token => temp_device_token).count).to eq(0)
  end

  it "will not allow two devices with same device_token" do
    my_device_token = "my very special device token"
    create_user
    register_device my_device_token
    register_device my_device_token

    expect(Device.where(:device_token => my_device_token).count).to eq(1)
  end
end
