Dir[File.join(File.dirname(__FILE__), '..',  'routes', '**/*.rb')].sort.each do |file|
  require file
end