require 'date'

class HelperPointDateHelper
  def self.get_date_array (number_of_days)
    now = Date.today
    start_date = now - number_of_days
    (start_date .. now).map{ |day| HelperPoint.new 0, "Empty", day }
  end
end
