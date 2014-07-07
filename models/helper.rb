class Helper < User
  many :helper_request, :foreign_key => :helper_id, :class_name => "HelperRequest"
  many :helper_points, :foreign_key => :user_id, :class_name => "HelperPoint"
  key :role, String
  
  before_create :set_role
  after_create :set_points

  def set_points() 
   if role == "helper"
    point = HelperPoint.signup
    self.helper_points.push point
  end 
end

def set_role()
  self.role = "helper"
end

def self.helpers_who_speaks_blind_persons_language request
  raise 'no blind person in call' if request.blind.nil?
 languages_of_blind = request.blind.languages
 TheLogger.log.error "languages_of_blind #{languages_of_blind}"
 Helper.where(:languages => {:$in => languages_of_blind})
end

  #TODO to be improved with snooze functionality
  def available request=nil, limit=5
    begin
      request_id = request.present? ? request.id : nil
      contacted_helpers = HelperRequest
      .where(:request_id => request_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)

      logged_in_users = Token
      .where(:expiry_time.gt => Time.now)
      .fields(:user_id)
      .all
      .collect(&:user_id)

      abusive_helpers = AbuseReport
      .where(:blind_id => request.blind_id)
      .fields(:helper_id)
      .all
      .collect(&:helper_id)

      blocked_users = User
      .where(:blocked => true)
      .fields(:user_id)
      .all
      .collect(&:user_id)

      awake_users = User.awake_users
      .where(:role=> 'helper')
      .fields(:user_id)
      .all
      .collect(&:user_id)

      non_snoozing_users = User.non_snoozing_users
      .where(:role=> 'helper')
      .fields(:user_id)
      .all
      .collect(&:user_id)

      helpers_who_speaks_blind_persons_language = Helper.helpers_who_speaks_blind_persons_language(request)
      .fields(:user_id)
      .all
      .collect(&:user_id)

      helpers_in_a_call = Request.running_requests
       .fields(:helper_id)
      .all
      .collect(&:helper_id)

    rescue Exception => e
      TheLogger.log.error e.message
    end
    Helper.where(:id.nin => contacted_helpers,
     :id.nin => abusive_helpers,
     :id.in => logged_in_users,
     :user_id.in => awake_users,
     :user_id.in => non_snoozing_users,
     :user_id.nin => blocked_users,
     :user_id.in => helpers_who_speaks_blind_persons_language,  
     :user_id.nin => helpers_in_a_call, 
     "$or" => [
       {:available_from => nil},
       {:available_from.lt => Time.now.utc}
       ]).all.sample(limit)
  end
end
