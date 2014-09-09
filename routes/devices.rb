require 'active_support'
require 'active_support/core_ext'
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

      device = update_device(device_token, nil, device_name, model, system_version, app_version, app_bundle_version, locale, development, inactive)
      
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
    old_device = Device.first(:device_token => device_token)
    unless old_device.nil?
      token = old_device.token
      user = old_device.user 
      old_device.destroy
    end

    new_device = Device.first(:device_token => new_device_token)
    new_device.destroy unless new_device.nil?

    if new_device_token.blank?
      new_device_token = device_token
    end

    begin 
      device = Device.new
      unless token.nil?
        device.token = token 
        token.device = device
     
        token.save!
      end
       
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

      unless user.nil?
        user.devices.push(device) 
        user.save!
      end

      device.save!
      device
    rescue Exception => e
      give_error(400, ERROR_DEVICE_ALREADY_EXIST, "Error updating device").to_json
    end
  end
end
