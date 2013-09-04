require 'mongomapper_id2'

class Helper < User

  key :role, String
  
  before_create :set_role
  
  def set_role()
    self.role = "helper"
  end
  
end