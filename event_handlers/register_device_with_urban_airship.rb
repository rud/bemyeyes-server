class RegisterDeviceWithUrbanAirship
  def initialize(requests_helper)
    @requests_helper = requests_helper
  end

  def register payload
    device_id = payload[:device_id]
    device = Device.first(:_id => device_id)

    return if device.nil? || device.inactive
    @requests_helper.register_device device.development, device.device_token, :alias => device.device_name, :tags => [ device.model, device.system_version, "v" + device.app_version, "v" + device.app_bundle_version, device.locale ]
  end
end
