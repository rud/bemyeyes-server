class HelperPointChecker
  def check_helper_points

    Helper.all().each do |helper|
      #Has the user already received point for 5 high fives in the last week
      if HelperPoint.all(:user_id => helper.id, :log_time.gte => 7.days.ago, :message => 'finish_5_high_fives_in_a_week').count > 0
        next
      end
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
