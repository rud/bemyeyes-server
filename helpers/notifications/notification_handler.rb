
class NotificationHandler
  def set_successor successor
    @successor = successor
  end

  def handle_notifications(devices, request)
    active_devices = devices.select {|device| not device.inactive}
    devices_not_handled = active_devices.reject {|device| include_device? device}
    devices_to_handle = active_devices.select {|device| include_device? device}

    if devices_to_handle.count > 0

      device_tokens = devices_to_handle.collect { |d| d.device_token }

      send_notifications request, device_tokens

      set_sent_helper devices_to_handle, request
    end
    
    if @successor and devices_not_handled.count > 0
      @successor.handle_notifications devices_not_handled, request
    end
  end

  private
  
  def set_sent_helper devices, request
    devices.each do |device|
      HelperRequest.create! :request => request, :helper => device.user
    end
  end
end