require 'event_bus'
class App < Sinatra::Base
    def self.requests_helper
        ua_config = settings.config['urbanairship']
        RequestsHelper.new ua_config, TheLogger
    end

    def self.setup_event_bus
        EventBus.subscribe(:request_stopped, MarkRequestStopped.new, :request_stopped)
        EventBus.subscribe(:request_stopped, AssignHelperPointsOnRequestStopped.new, :request_stopped)
        EventBus.subscribe(:request_answered, MarkRequestAnswered.new, :request_answered)
        # This should be changed hack for now
        EventBus.subscribe(:request_stopped, MarkRequestAnswered.new, :request_answered)
        EventBus.subscribe(:request_stopped, requests_helper, :request_answered)
        EventBus.subscribe(:request_answered, requests_helper, :request_answered)
        EventBus.subscribe(:request_cancelled, requests_helper, :request_answered)
        EventBus.subscribe(:request_cancelled, MarkHelperRequestCancelled.new, :helper_request_cancelled)
        EventBus.subscribe(:request_cancelled, MarkRequestNotAnsweredAnyway.new, :request_cancelled)
        EventBus.subscribe(:helper_notified, MarkHelperNotified.new, :helper_notified)
        EventBus.subscribe(:helper_notified, AssignLastHelpRequest.new, :helper_notified)

        send_reset_password_mail =SendResetPasswordMail.new settings
        EventBus.subscribe(:rest_password_token_created, send_reset_password_mail, :reset_password_token_created)

        unregister_device_with_urban_airship = UnRegisterDeviceWithUrbanAirship.new requests_helper
        EventBus.subscribe(:user_logged_out, unregister_device_with_urban_airship, :user_logged_out)

        register_device_with_urban_airship = RegisterDeviceWithUrbanAirship.new requests_helper
        EventBus.subscribe(:user_logged_in, register_device_with_urban_airship, :register)
        EventBus.subscribe(:device_created_or_updated, register_device_with_urban_airship, :register)
        EventBus.subscribe(:try_answer_request_but_already_answered, AssignHelperPointsOnTryAnswerAnsweredRequest.new, :answer_request)
        EventBus.subscribe(:abuse_report_filed, CreateAbuseReport.new, :abuse_report_filed)
        EventBus.subscribe(:abuse_report_filed, ThreeStrikesAndYouAreOut.new, :abuse_report_filed)
        EventBus.subscribe(EventLogger.new)
    end
    def self.ensure_indeces
        Helper.ensure_index(:last_help_request)
        HelperRequest.ensure_index(:request_id)
        Token.ensure_index(:expiry_time)
        User.ensure_index([[:wake_up_in_seconds_since_midnight, 1], [:go_to_sleep_in_seconds_since_midnight, 1], [:role, 1]])
        Helper.ensure_index(:lanugages)
    end
end
