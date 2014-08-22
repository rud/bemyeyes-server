class MarkRequestAnswered
  def request_answered(payload)
    request_id = payload[:request_id]
    helper = payload[:helper]

    request = Request.first(:_id => request_id)
    request.helper = helper
    request.answered = true
    request.save! 
  end
end