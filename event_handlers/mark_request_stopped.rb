class MarkRequestStopped
  def request_stopped(payload)
    request_id = payload[:request_id]

    request = Request.first(:_id => request_id)
    # Update request
    request.stopped = true
    request.save!
  end
end
