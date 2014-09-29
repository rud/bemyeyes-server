class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats' do
    get '/community' do

      return { 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count }.to_json
    end

    get '/profile/:token_repr' do
      token_repr = params[:token_repr]
      helper = helper_from_token token_repr

      no_helped = Request.count(:helper_id => helper._id, :answered => true)
      total_points = helper.helper_points.inject(0){|sum,x| sum + x.point }
      events = get_point_events helper
      current_level =  BMELevel.new("beginner", 0)
      next_level = BMELevel.new("rookie", 200)

      return {'no_helped' => no_helped, 'total_points' => total_points, 'events' => events, 'current_level'=> current_level, 'next_level' => next_level}.to_json
    end
  end
  
  class BMEPointEvent < Struct.new(:title, :date, :point)
  end

  class BMELevel < Struct.new(:title, :threshold)
  end

  def get_point_events helper

    events = helper.helper_points.collect{|point| BMEPointEvent.new(point.message,  point.log_time, point.point)}
    events
  end

  def helper_from_token token_repr
    token = token_from_representation(token_repr)
    user = token.user

    helper = Helper.first(:_id => user._id)
    helper
  end


  # Find token by representation of the token
  def token_from_representation(repr)
    token = Token.first(:token => repr)
    if token.nil?
      give_error(400, ERROR_USER_TOKEN_NOT_FOUND, "Token not found.").to_json
    end

    if !token.valid?
      give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
    end

    return token
  end
end
