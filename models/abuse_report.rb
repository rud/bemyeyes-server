class AbuseReport
  include MongoMapper::Document
  belongs_to :request, :class_name => "Request"
  belongs_to :blind, :class_name => "Blind"
  belongs_to :helper, :class_name => "Helper"
  key :reason, String, :required => true
  key :reporter, String, :required => true
  timestamps!
end
