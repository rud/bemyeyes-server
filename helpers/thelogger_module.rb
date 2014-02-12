module TheLogger
  def self.log
    @log ||= Logger.new('log/app.log', 10, 5242880)
  end
end