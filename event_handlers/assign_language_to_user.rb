class AssignLanguageToUser
  def user_saved(payload)
    user_id = payload[:user_id]
    user = User.first(:_id => user_id)
 
   return if user.nil?
   
   unless user.languages.include? 'en'
    user.languages << 'en'
    user.save!
   end 
  end
end