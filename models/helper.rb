class Helper < User
  many :helper_request, :foreign_key => :helper_id, :class_name => "HelperRequest"
  many :helper_points, :foreign_key => :user_id, :class_name => "HelperPoint"
  key :role, String
  
  before_create :set_role

  def set_role()
    self.role = "helper"
  end

  #TODO to be improved with snooze functionality
  def available request=nil, limit=5
    request_id = request.present? ? request.id : nil
    contacted_helpers = HelperRequest.where(:request_id => request_id).fields(:helper_id).all.collect(&:helper_id)
    logged_out_users = Token.where(:expiry_time.gt => Time.now).fields(:user_id).all.collect(&:user_id)
    Helper.where(:id.nin => contacted_helpers,
                 :id.in => logged_out_users,
                 "$or" => [
                     {:available_from => nil},
                     {:available_from.lt => Time.now.utc}
                 ]).all.sample(limit)
  end
end
