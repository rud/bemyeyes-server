class AbuseReport
  include MongoMapper::Document
  belongs_to :request, :class_name => "Request"
  key :reason, String, :required => true
  key :reporter, String, :required => true
  timestamps!
end
