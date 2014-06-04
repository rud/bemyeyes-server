class HelperRequest
  include MongoMapper::Document

  belongs_to :request, :class_name => "Request"
  belongs_to :helper, :class_name => "Helper"

  one :abuse_report, :foreign_key => :abuse_report_id, :class_name => "AbuseReport"
  timestamps!

end
