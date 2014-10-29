class CreateAbuseReport
  def abuse_report_filed(payload)
    request = payload[:request]
    reporter = payload[:reporter]
    reason = payload[:reason]
    abuse_report = AbuseReport.new
    abuse_report.request = request
    abuse_report.reason = reason
    abuse_report.reporter = reporter
    abuse_report.blind = request.blind
    abuse_report.helper = request.helper
    abuse_report.save!
  end
end
