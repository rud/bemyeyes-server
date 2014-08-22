class MarkRequestNotAnsweredAnyway
  def request_cancelled(payload)
    request_id = payload[:request_id]
    helper_id = payload[:helper_id]
     request = Request.first(:_id => request_id)
    # Update request
    request.helper = nil
    request.answered = false
    request.save!
  end
end
