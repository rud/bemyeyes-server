require_relative 'mark_request_answered'
require_relative 'mark_request_stopped'
require_relative 'mark_helper_request_cancelled'
require_relative 'mark_request_not_answered_anyway'
require_relative 'assign_helper_points_on_request_stopped'
Dir[Dir.pwd + "*.rb"].each { |f| require f }