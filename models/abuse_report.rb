class AbuseReport
  Include MongoMapper::Document
  belongs_to :helper_request, :class_name => "HelperRequest"
  key :reason, String, :required => true 
  timestamps!
end
