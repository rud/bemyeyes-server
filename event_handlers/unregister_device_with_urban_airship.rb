class UnRegisterDeviceWithUrbanAirship
  def initialize(requests_helper)
    @requests_helper = requests_helper
  end

  def user_logged_out(payload)
    device_id = payload[:device_id]
    device = Device.first(:_id => device_id)

    return if device.nil?

    @requests_helper.unregister_device device.development, device.device_token
  end
end
