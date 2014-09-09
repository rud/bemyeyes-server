class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/devices' do

    # Register device
    post '/register' do
      begin
        body_params = JSON.parse(request.body.read)
        device_token = body_params["device_token"]
        device_name = body_params["device_name"]
        model = body_params["model"]
        system_version = body_params["system_version"]
        app_version = body_params["app_version"]
        app_bundle_version = body_params["app_bundle_version"]
        locale = body_params["locale"]
        development = body_params["development"]
        inactive= body_params["inactive"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      device = register_device(device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)
      
      unless inactive
        EventBus.publish(:device_created_or_updated, device_id:device.id)
      end
      return { "success" => true, "token" => device_token }.to_json
    end

    post '/update' do
      begin
        body_params = JSON.parse(request.body.read)
        device_token = body_params["device_token"]
        new_device_token = body_params["new_device_token"]
        device_name = body_params["device_name"]
        model = body_params["model"]
        system_version = body_params["system_version"]
        app_version = body_params["app_version"]
        app_bundle_version = body_params["app_bundle_version"]
        locale = body_params["locale"]
        development = body_params["development"]
        inactive= body_params["inactive"]
     rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      device = update_device(device_token, new_device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)

      unless inactive
        EventBus.publish(:device_created_or_updated, device_id:device.id)
      end

      return { "success" => true, "token" => device_token }.to_json
    end
  end # End namespace /devices

  def update_device(device_token, new_device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)
    device = Device.first(:device_token => device_token)

    if new_device_token != device_token
      Device.first(:device_token => device_token).destroy
    end

    if new_device_token.nil? || new_device_token.to_s.strip.length == 0
      new_device_token = device_token
    end
    
    begin 
      device = Device.first(:device_token => new_device_token)

      token = device.token unless device.nil? || device.token.nil?
      device.destroy unless device.nil?
      device = Device.new
      device.token = token unless token.nil?
      token.device = device unless token.nil?

      # Update information
      device.device_token = new_device_token
      device.device_name = device_name
      device.model = model
      device.system_version = system_version
      device.app_version = app_version
      device.app_bundle_version = app_bundle_version
      device.locale = locale
      device.development = development
      device.inactive = inactive

      device.save!
      device
    rescue Exception => e
      give_error(400, ERROR_DEVICE_ALREADY_EXIST, "Error updating device").to_json
    end
  end

  def register_device(device_token, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)
    device = Device.first(:device_token => device_token)

    unless device.nil?
      device.token.destroy unless device.token.nil?
      device.destroy
    end

    # Create new device if it does not already exist
    device = Device.new

    # Update information
    device.device_token = device_token
    device.device_name = device_name
    device.model = model
    device.system_version = system_version
    device.app_version = app_version
    device.app_bundle_version = app_bundle_version
    device.locale = locale
    device.development = development
    device.inactive = inactive

    device.save!
    device
  end
end
