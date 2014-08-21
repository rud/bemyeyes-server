class AssignLastHelpRequest
  def helper_notified(payload)
    helper = payload[:helper]
    helper.last_help_request = Time.now
    helper.save!
  end
end