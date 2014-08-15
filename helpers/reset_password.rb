class ResetPasswordService
  def initialize logger
    @logger = logger
  end
  def reset_password token, password
    token = ResetPasswordToken.first({:token => token})
    if token.nil?
      return false, "User not found"
    end

    user = token.user
    user.password = password
    user.save!
    token.delete

    @logger.log.info( "Password changed for user with id #{token.user._id}")
    return true, "Password Changed!"
  end
end
