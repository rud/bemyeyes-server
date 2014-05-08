class HelperPointChecker
  def check_helper_points

    Helper.all().each do |helper|
      if HelperRequest.all(:helper_id =>helper.id, :updated_at.gte => 7.days.ago).count > 4
         add_helper_point helper
       end
     end 
    end

    def add_helper_point(helper)
      point = HelperPoint.finish_5_high_fives_in_a_week
        point.save
        helper.helper_points.push point
        helper.save  
    end
  
end