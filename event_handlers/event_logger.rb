require_relative '../models/event_log_object'

class EventLogger

  def method_missing(meth, *args, &block)
    event_name = meth.to_s
    event_log = EventLog.new
    event_log.name = event_name

    args[0].each_with_index do |(key, value), index|
      #first entry is the event_name
      next if index == 0
      event_logger_object = EventLogObject.new
      event_logger_object.name = key
      event_logger_object.json_serialized = value.to_json
      event_log.event_log_objects << event_logger_object
    end
    event_log.save!
  end

  def respond_to?(meth, include_private = false)
    true
  end
end
