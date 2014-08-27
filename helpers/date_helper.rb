require 'date'

class HelperPointDateHelper
  def self.get_date_array (number_of_days)
    now = Date.today
    start_date = now - number_of_days
    (start_date .. now).map{ |day| HelperPoint.new 0, "Empty", day }
  end

  def self.get_aggregated_points_for_each_day(helper, number_of_days)
    empty_days_array = HelperPointDateHelper.get_date_array number_of_days

    days_from_db =helper.helper_points.where(:log_time.gte => number_of_days.days.ago)

    merged_days = days_from_db.to_a | empty_days_array
    grouped_merged_days = merged_days.group_by  {|a| a.log_time.strftime "%Y-%m-%d"}
    sums = Array.new
    log_time = nil
    grouped_merged_days.each do |id,values|
      sum = 0

      values.each do |x|
        sum += x.point
        log_time = x.log_time

      end
      sums << HelperPoint.new(sum, "day", log_time )
    end
    sums
  end

end
