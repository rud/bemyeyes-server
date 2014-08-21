Dir[File.join(File.dirname(__FILE__), '..',  'event_handlers', '**/*.rb')].sort.each do |file|
  require file
end