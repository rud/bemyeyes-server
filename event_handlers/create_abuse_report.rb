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
        if reporter == 'blind'
            helper = request.helper
            helper.abuse_reports.push abuse_report
            helper.save!
        else
            blind = request.blind
            blind.abuse_reports.push abuse_report
            blind.save!
        end
    end
end
