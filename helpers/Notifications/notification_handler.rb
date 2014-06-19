
class NotificationHandler
  def set_successor successor
    @successor = successor
  end

  def handle_notifications(devices, request)
    TheLogger.log.error devices.flatten
    devices_not_handled = devices.reject {|device| not include_device? device}
    devices_to_handle = devices.reject {|device| include_device? device}
    
    device_tokens = devices_to_handle.collect { |d| d.device_token }
    send_notifications request, device_tokens

    set_sent_helper helpers, request

    if @successor and devices_not_handled.count > 0
      @successor.handle_notifications devices_not_handled
    end
  end

  private
  
  def set_sent_helper helpers, request
    helpers.each do |helper|
      HelperRequest.create! :request => request, :helper => helper
    end
  end
end