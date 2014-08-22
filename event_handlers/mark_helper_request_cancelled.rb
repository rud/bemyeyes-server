class MarkHelperRequestCancelled
  def helper_request_cancelled(payload)
    request_id = payload[:request_id]
    helper_id = payload[:helper_id]

    helper_request = HelperRequest.first(:request_id => request_id, :helper_id => helper_id)
    helper_request.cancelled = true
    helper_request.save!
  end
end
