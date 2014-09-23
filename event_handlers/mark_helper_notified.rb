class MarkHelperNotified
  def helper_notified(payload)
    request = payload[:request]
    helper = payload[:helper]
    HelperRequest.create! :request => request, :helper => helper
  end
end
