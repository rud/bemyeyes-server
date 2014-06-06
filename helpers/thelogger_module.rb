module TheLogger
  def self.log
    @log ||= Logger.new('log/app.log', 'daily')
  end
end
