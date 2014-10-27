require "sinatra/jsonp"

class App < Sinatra::Base
  register Sinatra::Namespace
  helpers Sinatra::Jsonp
  namespace '/stats' do
    before do
      next unless request.post? || request.put?
      @body_params = JSON.parse(request.body.read)
    end

    def body_params
      @body_params
    end

    get '/community' do
      return jsonp ({ 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count })
    end

    get '/profile/:token_repr' do
      token_repr = params[:token_repr]
      helper = helper_from_token token_repr

      no_helped = Request.count(:helper_id => helper._id, :answered => true)
      total_points = helper.points
      events = get_point_events helper
      current_level =  user_level_to_BMELevel helper.user_level
      next_level = user_level_to_BMELevel helper.user_level.next_user_level

      return {'no_helped' => no_helped, 'total_points' => total_points, 'events' => events, 'current_level'=> current_level, 'next_level' => next_level}.to_json
    end

    post '/event' do
      begin
      token_repr = body_params['token_repr']
      event = body_params['event']

      unless HelperPoint.point_type_exists? event.to_s
        give_error(400, ERROR_INVALID_BODY, "Event not found").to_json
      end

      helper = helper_from_token_repr token_repr

      # these events can only be registered once
      if helper.helper_points.any? { | point | point.message == event }
        give_error(400, ERROR_NOT_PERMITTED, "Event already registred").to_json
      end

      point = HelperPoint.send(event)
      helper.helper_points.push point
      helper.save
       rescue => error
        give_error(400, ERROR_INVALID_BODY, "Error").to_json
      end
      {:status => "OK"}.to_json
    end

    get '/actionable_tasks/:token_repr' do
      begin
        token_repr = params[:token_repr]
        helper = helper_from_token_repr token_repr

        completed_point_events = get_point_events helper
        all_point_events = get_points_events_from_hash HelperPoint.actionable_points

        remaining_tasks = 
        all_point_events.select do |point|
           not completed_point_events.any? { | completed_point | completed_point.event== point.event}
        end

        completed_tasks =
        completed_point_events.select do |point|
           all_point_events.any? { | completed_point | completed_point.event == point.event}
        end

        BMERemainingTasks.new(remaining_tasks, completed_tasks).to_json
      rescue
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end
  end
class BMERemainingTasks< Struct.new(:remaining_tasks, :completed_tasks)
end
  def helper_from_token_repr token_repr
    token = token_from_representation(token_repr)
    user = token.user
    helper_from_id user._id
  end

  class BMEPointEvent < Struct.new(:event, :date, :point)
  end

  class BMELevel < Struct.new(:title, :threshold)
  end

  def user_level_to_BMELevel user_level
    BMELevel.new(user_level.name, user_level.point_threshold)
  end

  def get_points_events_from_hash points_hash
    events = points_hash.collect{| message, point | BMEPointEvent.new(message, nil, point)}
    events
  end

  def get_point_events helper
    helper.helper_points.collect{|point| BMEPointEvent.new(point.message,  point.log_time, point.point)}
  end
end
