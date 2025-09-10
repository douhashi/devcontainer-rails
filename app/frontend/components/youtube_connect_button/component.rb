module YoutubeConnectButton
  class Component < ApplicationViewComponent
    attr_reader :user, :connect_classes, :disconnect_classes

    def initialize(user:, connect_text: nil, disconnect_text: nil, connect_classes: nil, disconnect_classes: nil)
      @user = user
      @custom_connect_text = connect_text
      @custom_disconnect_text = disconnect_text
      @connect_classes = connect_classes || default_connect_classes
      @disconnect_classes = disconnect_classes || default_disconnect_classes
    end

    def connect_text
      @custom_connect_text || I18n.t("youtube_connect_button.component.connect")
    end

    def disconnect_text
      @custom_disconnect_text || I18n.t("youtube_connect_button.component.disconnect")
    end

    def connected?
      user.youtube_connected?
    end

    def button_text
      connected? ? disconnect_text : connect_text
    end

    def button_path
      connected? ? youtube_auth_disconnect_path : youtube_auth_authorize_path
    end

    def button_method
      connected? ? :delete : :get
    end

    def button_classes
      connected? ? disconnect_classes : connect_classes
    end

    def data_attributes
      if connected?
        {
          turbo_method: :delete,
          turbo_confirm: I18n.t("youtube_connect_button.component.confirm_disconnect")
        }
      else
        {}
      end
    end

    private

    def default_connect_classes
      "bg-red-600 hover:bg-red-700 text-white font-medium py-2 px-4 rounded-md inline-flex items-center gap-2"
    end

    def default_disconnect_classes
      "bg-gray-600 hover:bg-gray-700 text-white font-medium py-2 px-4 rounded-md inline-flex items-center gap-2"
    end
  end
end
