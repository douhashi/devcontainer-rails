require 'rails_helper'

RSpec.describe YoutubeService do
  before do
    # CI環境で環境変数が設定されていない場合のためにスタブ化
    ENV['YOUTUBE_CLIENT_ID'] ||= 'test_client_id'
    ENV['YOUTUBE_CLIENT_SECRET'] ||= 'test_client_secret'
    ENV['YOUTUBE_REDIRECT_URI'] ||= 'http://localhost:5100/auth/youtube/callback'
  end

  let(:service) { described_class.new }

  describe '#initialize' do
    context 'when all required credentials are set' do
      it 'initializes successfully' do
        expect { service }.not_to raise_error
      end
    end

    context 'when CLIENT_ID is missing' do
      it 'raises an authentication error' do
        original_id = ENV['YOUTUBE_CLIENT_ID']
        ENV.delete('YOUTUBE_CLIENT_ID')

        expect { described_class.new }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /Missing required YouTube API credentials.*YOUTUBE_CLIENT_ID/
        )

        ENV['YOUTUBE_CLIENT_ID'] = original_id
      end
    end

    context 'when CLIENT_SECRET is missing' do
      it 'raises an authentication error' do
        original_secret = ENV['YOUTUBE_CLIENT_SECRET']
        ENV.delete('YOUTUBE_CLIENT_SECRET')

        expect { described_class.new }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /Missing required YouTube API credentials.*YOUTUBE_CLIENT_SECRET/
        )

        ENV['YOUTUBE_CLIENT_SECRET'] = original_secret
      end
    end

    context 'when REDIRECT_URI is missing' do
      it 'raises an authentication error' do
        original_uri = ENV['YOUTUBE_REDIRECT_URI']
        ENV.delete('YOUTUBE_REDIRECT_URI')

        expect { described_class.new }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /Missing required YouTube API credentials.*YOUTUBE_REDIRECT_URI/
        )

        ENV['YOUTUBE_REDIRECT_URI'] = original_uri
      end
    end

    context 'when multiple credentials are missing' do
      it 'lists all missing credentials in error message' do
        original_id = ENV['YOUTUBE_CLIENT_ID']
        original_secret = ENV['YOUTUBE_CLIENT_SECRET']
        ENV.delete('YOUTUBE_CLIENT_ID')
        ENV.delete('YOUTUBE_CLIENT_SECRET')

        expect { described_class.new }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /Missing required YouTube API credentials.*YOUTUBE_CLIENT_ID.*YOUTUBE_CLIENT_SECRET/
        )

        ENV['YOUTUBE_CLIENT_ID'] = original_id
        ENV['YOUTUBE_CLIENT_SECRET'] = original_secret
      end
    end

    context 'with custom credentials' do
      it 'accepts custom client_id, client_secret, and redirect_uri' do
        custom_service = described_class.new(
          client_id: 'custom_client_id',
          client_secret: 'custom_secret',
          redirect_uri: 'http://custom.com/callback'
        )

        expect(custom_service.send(:client_id)).to eq('custom_client_id')
        expect(custom_service.send(:client_secret)).to eq('custom_secret')
        expect(custom_service.send(:redirect_uri)).to eq('http://custom.com/callback')
      end
    end
  end

  describe '#authorization_url' do
    let(:mock_account) { double('Yt::Account') }
    let(:expected_url) { 'https://accounts.google.com/oauth2/auth?client_id=test&redirect_uri=...' }

    before do
      allow(Yt::Account).to receive(:new).and_return(mock_account)
    end

    context 'with default parameters' do
      it 'generates authorization URL with default scope' do
        expect(mock_account).to receive(:authorization_url).with(
          scope: "https://www.googleapis.com/auth/youtube.readonly",
          redirect_uri: ENV['YOUTUBE_REDIRECT_URI'],
          state: nil
        ).and_return(expected_url)

        result = service.authorization_url
        expect(result).to eq(expected_url)
      end
    end

    context 'with custom scope and state' do
      it 'generates authorization URL with custom parameters' do
        custom_scope = "https://www.googleapis.com/auth/youtube.upload"
        custom_state = "random_state_123"

        expect(mock_account).to receive(:authorization_url).with(
          scope: custom_scope,
          redirect_uri: ENV['YOUTUBE_REDIRECT_URI'],
          state: custom_state
        ).and_return(expected_url)

        result = service.authorization_url(scope: custom_scope, state: custom_state)
        expect(result).to eq(expected_url)
      end
    end

    context 'when yt gem raises RequestError' do
      it 'handles authentication errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "authError"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /YouTube authentication failed/
        )
      end

      it 'handles quota exceeded errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "quotaExceeded"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::QuotaExceededError,
          /YouTube API quota exceeded/
        )
      end

      it 'handles rate limit errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "rateLimitExceeded"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::RateLimitError,
          /YouTube API rate limit exceeded/
        )
      end

      it 'handles not found errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "notFound"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::NotFoundError,
          /YouTube resource not found/
        )
      end

      it 'handles generic errors based on message content' do
        error_response = {
          "error" => {
            "errors" => [ { "reason" => "authError", "message" => "Authentication failed" } ]
          }
        }
        error = Yt::Errors::RequestError.new('authentication failed')
        allow(error).to receive(:reasons).and_return([ "authError" ])
        allow(error).to receive(:response_body).and_return(error_response)

        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /YouTube authentication failed/
        )
      end

      it 'handles other API errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "unknownError"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::ApiError,
          /YouTube API error/
        )
      end
    end

    context 'when yt gem raises unexpected error' do
      it 'wraps unexpected errors' do
        allow(mock_account).to receive(:authorization_url).and_raise(StandardError.new('Unexpected error'))

        expect { service.authorization_url }.to raise_error(
          Youtube::Errors::ApiError,
          /Unexpected error.*Unexpected error/
        )
      end
    end
  end

  describe '#authenticate' do
    let(:authorization_code) { 'test_authorization_code_123' }
    let(:mock_account) { double('Yt::Account') }

    before do
      allow(Yt::Account).to receive(:new).and_return(mock_account)
    end

    context 'with valid authorization code' do
      it 'authenticates and returns account' do
        expect(mock_account).to receive(:authenticate!).with(
          code: authorization_code,
          redirect_uri: ENV['YOUTUBE_REDIRECT_URI']
        ).and_return(mock_account)

        result = service.authenticate(authorization_code: authorization_code)
        expect(result).to eq(mock_account)
      end

      it 'stores authenticated account for later use' do
        allow(mock_account).to receive(:authenticate!).and_return(mock_account)

        service.authenticate(authorization_code: authorization_code)

        # After authentication, client method should return the account
        expect(service.client).to eq(mock_account)
      end
    end

    context 'with error handling' do
      it 'handles authentication errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "authError"}]}}}')
        allow(mock_account).to receive(:authenticate!).and_raise(error)

        expect { service.authenticate(authorization_code: authorization_code) }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /YouTube authentication failed/
        )
      end

      it 'handles quota exceeded errors' do
        error = Yt::Errors::RequestError.new('quota exceeded')
        allow(error).to receive(:reasons).and_return([ "quotaExceeded" ])
        allow(error).to receive(:response_body).and_return({})

        allow(mock_account).to receive(:authenticate!).and_raise(error)

        expect { service.authenticate(authorization_code: authorization_code) }.to raise_error(
          Youtube::Errors::QuotaExceededError,
          /YouTube API quota exceeded/
        )
      end
    end
  end

  describe '#client' do
    context 'when not authenticated' do
      it 'raises authentication error' do
        expect { service.client }.to raise_error(
          Youtube::Errors::AuthenticationError,
          'Not authenticated. Call authenticate first.'
        )
      end
    end

    context 'when authenticated' do
      let(:mock_account) { double('Yt::Account') }

      before do
        allow(Yt::Account).to receive(:new).and_return(mock_account)
        allow(mock_account).to receive(:authenticate!).and_return(mock_account)

        service.authenticate(authorization_code: 'test_code')
      end

      it 'returns authenticated account' do
        expect(service.client).to eq(mock_account)
      end
    end
  end

  describe 'retry mechanism' do
    let(:mock_account) { double('Yt::Account') }

    before do
      allow(Yt::Account).to receive(:new).and_return(mock_account)
      allow(Rails.logger).to receive(:info)
      allow(service).to receive(:sleep) # Speed up tests
    end

    context 'with rate limit errors' do
      it 'retries up to MAX_RETRIES times with exponential backoff' do
        call_count = 0
        allow(mock_account).to receive(:authorization_url) do
          call_count += 1
          if call_count < 3
            error = Yt::Errors::RequestError.new('rate limit exceeded')
            allow(error).to receive(:reasons).and_return([ "rateLimitExceeded" ])
            allow(error).to receive(:response_body).and_return({})
            raise error
          else
            'success_url'
          end
        end

        expect(service).to receive(:sleep).with(2).once # 1 * 2^1
        expect(service).to receive(:sleep).with(4).once # 1 * 2^2

        result = service.authorization_url
        expect(result).to eq('success_url')
        expect(call_count).to eq(3)
      end

      it 'gives up after MAX_RETRIES attempts' do
        error = Yt::Errors::RequestError.new('rate limit exceeded')
        allow(error).to receive(:reasons).and_return([ "rateLimitExceeded" ])
        allow(error).to receive(:response_body).and_return({})

        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect { service.authorization_url }.to raise_error(Youtube::Errors::RateLimitError)
      end

      it 'logs retry attempts' do
        call_count = 0
        allow(mock_account).to receive(:authorization_url) do
          call_count += 1
          if call_count < 2
            error = Yt::Errors::RequestError.new('rate limit exceeded')
            allow(error).to receive(:reasons).and_return([ "rateLimitExceeded" ])
            allow(error).to receive(:response_body).and_return({})
            raise error
          else
            'success_url'
          end
        end

        expect(Rails.logger).to receive(:info).with(
          a_string_including("attempt 2/3")
        )

        service.authorization_url
      end
    end

    context 'with non-retryable errors' do
      it 'does not retry authentication errors' do
        error = Yt::Errors::RequestError.new('authentication failed')
        allow(error).to receive(:reasons).and_return([ "authError" ])
        allow(error).to receive(:response_body).and_return({})

        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect(service).not_to receive(:sleep)
        expect { service.authorization_url }.to raise_error(Youtube::Errors::AuthenticationError)
      end

      it 'does not retry API errors' do
        error = Yt::Errors::RequestError.new('{"response_body": {"error": {"errors": [{"reason": "badRequest"}]}}}')
        allow(mock_account).to receive(:authorization_url).and_raise(error)

        expect(service).not_to receive(:sleep)
        expect { service.authorization_url }.to raise_error(Youtube::Errors::ApiError)
      end
    end
  end

  describe 'error response details' do
    let(:mock_account) { double('Yt::Account') }

    before do
      allow(Yt::Account).to receive(:new).and_return(mock_account)
    end

    it 'includes response code and body in error objects' do
      response_body_json = '{"response_body": {"error": {"message": "Invalid client credentials", "errors": [{"reason": "authError"}]}}}'
      error = Yt::Errors::RequestError.new(response_body_json)
      allow(mock_account).to receive(:authorization_url).and_raise(error)

      begin
        service.authorization_url
      rescue Youtube::Errors::AuthenticationError => e
        expect(e.response_code).to be_nil # yt gem doesn't provide status_code directly
        expect(e.response_body).to eq(error.response_body)
      end
    end
  end

  describe '#get_channel' do
    let(:channel_id) { 'UCXuqSBlHAE6Xw-yeJA0Tunw' }  # Test channel ID
    let(:channel_handle) { '@LofiBGM-111' }  # Target channel handle
    let(:mock_channel) { double('Yt::Channel') }

    before do
      allow(Yt::Channel).to receive(:new).and_return(mock_channel)
    end

    context 'with valid channel ID' do
      it 'returns channel information successfully' do
        expected_data = {
          title: 'Test Channel',
          description: 'Test Description',
          subscriber_count: 1000,
          video_count: 50,
          view_count: 100000
        }

        allow(mock_channel).to receive(:title).and_return(expected_data[:title])
        allow(mock_channel).to receive(:description).and_return(expected_data[:description])
        allow(mock_channel).to receive(:subscriber_count).and_return(expected_data[:subscriber_count])
        allow(mock_channel).to receive(:video_count).and_return(expected_data[:video_count])
        allow(mock_channel).to receive(:view_count).and_return(expected_data[:view_count])

        result = service.get_channel(channel_id)

        expect(result).to eq(expected_data)
        expect(Yt::Channel).to have_received(:new).with(id: channel_id, api_key: nil)
      end

      it 'logs channel information retrieval' do
        allow(mock_channel).to receive(:title).and_return('Test Channel')
        allow(mock_channel).to receive(:description).and_return('Test Description')
        allow(mock_channel).to receive(:subscriber_count).and_return(1000)
        allow(mock_channel).to receive(:video_count).and_return(50)
        allow(mock_channel).to receive(:view_count).and_return(100000)

        expect(Rails.logger).to receive(:info).with(/Retrieving YouTube channel information/)
        expect(Rails.logger).to receive(:info).with(/Successfully retrieved channel information/)

        service.get_channel(channel_id)
      end
    end

    context 'with valid channel handle' do
      it 'converts handle to channel ID and returns channel information' do
        expected_data = {
          title: 'LofiBGM Channel',
          description: 'Lofi music channel',
          subscriber_count: 5000,
          video_count: 100,
          view_count: 500000
        }

        allow(mock_channel).to receive(:title).and_return(expected_data[:title])
        allow(mock_channel).to receive(:description).and_return(expected_data[:description])
        allow(mock_channel).to receive(:subscriber_count).and_return(expected_data[:subscriber_count])
        allow(mock_channel).to receive(:video_count).and_return(expected_data[:video_count])
        allow(mock_channel).to receive(:view_count).and_return(expected_data[:view_count])

        result = service.get_channel(channel_handle)

        expect(result).to eq(expected_data)
        expect(Yt::Channel).to have_received(:new).with(
          id: 'UCxYJQNWjcK7pK5JLNfHsz6w',
          api_key: nil
        )
      end

      it 'raises ArgumentError for unknown handle' do
        unknown_handle = '@UnknownChannel'

        expect { service.get_channel(unknown_handle) }.to raise_error(
          ArgumentError,
          /Unknown channel handle.*@UnknownChannel/
        )
      end
    end

    context 'with blank or nil input' do
      it 'raises ArgumentError for nil channel identifier' do
        expect { service.get_channel(nil) }.to raise_error(
          ArgumentError,
          'Channel identifier cannot be blank'
        )
      end

      it 'raises ArgumentError for empty string' do
        expect { service.get_channel('') }.to raise_error(
          ArgumentError,
          'Channel identifier cannot be blank'
        )
      end

      it 'raises ArgumentError for whitespace string' do
        expect { service.get_channel('  ') }.to raise_error(
          ArgumentError,
          'Channel identifier cannot be blank'
        )
      end
    end

    context 'with API errors' do
      it 'handles not found errors' do
        error = Yt::Errors::RequestError.new('Channel not found')
        allow(error).to receive(:reasons).and_return([ 'notFound' ])
        allow(error).to receive(:response_body).and_return({})
        allow(Yt::Channel).to receive(:new).and_raise(error)

        expect { service.get_channel('invalid_channel_id') }.to raise_error(
          Youtube::Errors::NotFoundError,
          /YouTube resource not found/
        )
      end

      it 'handles authentication errors' do
        error = Yt::Errors::RequestError.new('Authentication failed')
        allow(error).to receive(:reasons).and_return([ 'authError' ])
        allow(error).to receive(:response_body).and_return({})
        allow(Yt::Channel).to receive(:new).and_raise(error)

        expect { service.get_channel(channel_id) }.to raise_error(
          Youtube::Errors::AuthenticationError,
          /YouTube authentication failed/
        )
      end

      it 'handles quota exceeded errors' do
        error = Yt::Errors::RequestError.new('Quota exceeded')
        allow(error).to receive(:reasons).and_return([ 'quotaExceeded' ])
        allow(error).to receive(:response_body).and_return({})
        allow(Yt::Channel).to receive(:new).and_raise(error)

        expect { service.get_channel(channel_id) }.to raise_error(
          Youtube::Errors::QuotaExceededError,
          /YouTube API quota exceeded/
        )
      end

      it 'handles rate limit errors with retry mechanism' do
        call_count = 0
        allow(Yt::Channel).to receive(:new) do
          call_count += 1
          if call_count < 3
            error = Yt::Errors::RequestError.new('Rate limit exceeded')
            allow(error).to receive(:reasons).and_return([ 'rateLimitExceeded' ])
            allow(error).to receive(:response_body).and_return({})
            raise error
          else
            mock_channel
          end
        end

        allow(mock_channel).to receive(:title).and_return('Test Channel')
        allow(mock_channel).to receive(:description).and_return('Test Description')
        allow(mock_channel).to receive(:subscriber_count).and_return(1000)
        allow(mock_channel).to receive(:video_count).and_return(50)
        allow(mock_channel).to receive(:view_count).and_return(100000)

        allow(service).to receive(:sleep) # Speed up tests

        expect(Rails.logger).to receive(:info).exactly(6).times # Retrieving(3) + retry attempts(2) + Successfully(1)
        result = service.get_channel(channel_id)

        expect(result[:title]).to eq('Test Channel')
        expect(call_count).to eq(3)
      end

      it 'handles generic API errors' do
        error = Yt::Errors::RequestError.new('Unknown API error')
        allow(error).to receive(:reasons).and_return([ 'unknownError' ])
        allow(error).to receive(:response_body).and_return({})
        allow(Yt::Channel).to receive(:new).and_raise(error)

        expect { service.get_channel(channel_id) }.to raise_error(
          Youtube::Errors::ApiError,
          /YouTube API error/
        )
      end
    end

    context 'with channel data access errors' do
      it 'handles errors when accessing channel properties' do
        allow(Yt::Channel).to receive(:new).and_return(mock_channel)

        error = Yt::Errors::RequestError.new('Data access error')
        allow(error).to receive(:reasons).and_return([ 'dataError' ])
        allow(error).to receive(:response_body).and_return({})
        allow(mock_channel).to receive(:title).and_raise(error)

        expect { service.get_channel(channel_id) }.to raise_error(
          Youtube::Errors::ApiError,
          /YouTube API error/
        )
      end

      it 'handles missing channel data gracefully' do
        allow(Yt::Channel).to receive(:new).and_return(mock_channel)
        allow(mock_channel).to receive(:title).and_return(nil)
        allow(mock_channel).to receive(:description).and_return('')
        allow(mock_channel).to receive(:subscriber_count).and_return(0)
        allow(mock_channel).to receive(:video_count).and_return(0)
        allow(mock_channel).to receive(:view_count).and_return(0)

        result = service.get_channel(channel_id)

        expect(result[:title]).to be_nil
        expect(result[:description]).to eq('')
        expect(result[:subscriber_count]).to eq(0)
        expect(result[:video_count]).to eq(0)
        expect(result[:view_count]).to eq(0)
      end
    end
  end

  describe '.test_connection' do
    context 'as a class method for easy console testing' do
      it 'provides easy access to channel connection test' do
        mock_service = double('YoutubeService')
        expected_result = {
          title: 'Test Channel',
          description: 'Test Description',
          subscriber_count: 1000,
          video_count: 50,
          view_count: 100000
        }

        allow(described_class).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:get_channel).with('@LofiBGM-111').and_return(expected_result)

        result = described_class.test_connection

        expect(result).to eq(expected_result)
        expect(mock_service).to have_received(:get_channel).with('@LofiBGM-111')
      end

      it 'accepts custom channel identifier' do
        mock_service = double('YoutubeService')
        custom_channel = 'UCXuqSBlHAE6Xw-yeJA0Tunw'
        expected_result = {
          title: 'Custom Channel',
          description: 'Custom Description',
          subscriber_count: 2000,
          video_count: 75,
          view_count: 200000
        }

        allow(described_class).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:get_channel).with(custom_channel).and_return(expected_result)

        result = described_class.test_connection(custom_channel)

        expect(result).to eq(expected_result)
        expect(mock_service).to have_received(:get_channel).with(custom_channel)
      end

      it 'logs the connection test attempt' do
        mock_service = double('YoutubeService')
        allow(described_class).to receive(:new).and_return(mock_service)
        allow(mock_service).to receive(:get_channel).and_return({})

        expect(Rails.logger).to receive(:info).with(/Testing YouTube channel connection/)

        described_class.test_connection
      end
    end
  end

  describe '#get_videos' do
    let(:channel_id) { 'UCxYJQNWjcK7pK5JLNfHsz6w' }
    let(:channel_handle) { '@LofiBGM-111' }
    let(:mock_channel) { double('Yt::Channel') }
    let(:mock_videos) { double('Yt::Collections::Videos') }
    let(:mock_video1) { double('Yt::Video') }
    let(:mock_video2) { double('Yt::Video') }

    before do
      allow(Yt::Channel).to receive(:new).and_return(mock_channel)
      allow(mock_channel).to receive(:videos).and_return(mock_videos)

      # デフォルトの動画モック設定
      allow(mock_video1).to receive(:id).and_return('video_id_1')
      allow(mock_video1).to receive(:title).and_return('Test Video 1')
      allow(mock_video1).to receive(:description).and_return('Test description 1')
      allow(mock_video1).to receive(:published_at).and_return(Time.parse('2024-01-01 12:00:00 UTC'))
      allow(mock_video1).to receive(:view_count).and_return(1000)
      allow(mock_video1).to receive(:like_count).and_return(50)
      allow(mock_video1).to receive(:duration).and_return(180)
      allow(mock_video1).to receive_message_chain(:thumbnails, :default, :url).and_return('https://example.com/thumb1.jpg')

      allow(mock_video2).to receive(:id).and_return('video_id_2')
      allow(mock_video2).to receive(:title).and_return('Test Video 2')
      allow(mock_video2).to receive(:description).and_return('Test description 2')
      allow(mock_video2).to receive(:published_at).and_return(Time.parse('2024-01-02 12:00:00 UTC'))
      allow(mock_video2).to receive(:view_count).and_return(2000)
      allow(mock_video2).to receive(:like_count).and_return(100)
      allow(mock_video2).to receive(:duration).and_return(240)
      allow(mock_video2).to receive_message_chain(:thumbnails, :default, :url).and_return('https://example.com/thumb2.jpg')
    end

    context 'with valid channel identifier' do
      it 'returns structured video data with default pagination' do
        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1, mock_video2 ])

        result = service.get_videos(channel_handle)

        expect(result).to be_a(Hash)
        expect(result[:videos]).to be_an(Array)
        expect(result[:videos].size).to eq(2)
        expect(result[:pagination][:limit]).to eq(50)
        expect(result[:pagination][:offset]).to eq(0)
        expect(result[:pagination][:returned_count]).to eq(2)

        first_video = result[:videos].first
        expect(first_video[:id]).to eq('video_id_1')
        expect(first_video[:title]).to eq('Test Video 1')
        expect(first_video[:description]).to eq('Test description 1')
        expect(first_video[:published_at]).to eq(Time.parse('2024-01-01 12:00:00 UTC'))
        expect(first_video[:view_count]).to eq(1000)
        expect(first_video[:like_count]).to eq(50)
        expect(first_video[:duration]).to eq(180)
        expect(first_video[:thumbnail_url]).to eq('https://example.com/thumb1.jpg')
      end

      it 'handles custom limit and offset parameters' do
        allow(mock_videos).to receive(:drop).with(10).and_return(mock_videos)
        allow(mock_videos).to receive(:take).with(25).and_return([ mock_video1 ])

        result = service.get_videos(channel_handle, limit: 25, offset: 10)

        expect(result[:videos].size).to eq(1)
        expect(result[:pagination][:limit]).to eq(25)
        expect(result[:pagination][:offset]).to eq(10)
        expect(result[:pagination][:returned_count]).to eq(1)
      end

      it 'works with channel ID directly' do
        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1 ])

        result = service.get_videos(channel_id)

        expect(result[:videos].size).to eq(1)
        expect(Yt::Channel).to have_received(:new).with(id: channel_id, api_key: ENV["YOUTUBE_API_KEY"])
      end

      it 'logs video retrieval process' do
        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1 ])

        expect(Rails.logger).to receive(:info).with(/Retrieving videos for channel/)
        expect(Rails.logger).to receive(:info).with(/Successfully retrieved \d+ videos/)

        service.get_videos(channel_handle)
      end

      it 'filters out videos with missing required data' do
        broken_video = double('Yt::Video')
        allow(broken_video).to receive(:id).and_raise(StandardError.new("Video unavailable"))

        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1, broken_video, mock_video2 ])

        result = service.get_videos(channel_handle)

        expect(result[:videos].size).to eq(2)
        expect(result[:videos].map { |v| v[:id] }).to contain_exactly('video_id_1', 'video_id_2')
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError for blank channel identifier' do
        expect { service.get_videos('') }.to raise_error(
          ArgumentError,
          'Channel identifier cannot be blank'
        )

        expect { service.get_videos(nil) }.to raise_error(
          ArgumentError,
          'Channel identifier cannot be blank'
        )
      end

      it 'raises ArgumentError for negative limit' do
        expect { service.get_videos(channel_handle, limit: -1) }.to raise_error(
          ArgumentError,
          'Limit must be greater than 0'
        )
      end

      it 'raises ArgumentError for negative offset' do
        expect { service.get_videos(channel_handle, offset: -1) }.to raise_error(
          ArgumentError,
          'Offset must be greater than or equal to 0'
        )
      end

      it 'raises ArgumentError for limit exceeding maximum' do
        expect { service.get_videos(channel_handle, limit: 1001) }.to raise_error(
          ArgumentError,
          'Limit cannot exceed 1000'
        )
      end
    end

    context 'with API errors' do
      it 'handles channel not found errors' do
        error = Yt::Errors::RequestError.new('Channel not found')
        allow(error).to receive(:reasons).and_return([ 'notFound' ])
        allow(error).to receive(:response_body).and_return({})
        allow(Yt::Channel).to receive(:new).and_raise(error)

        expect { service.get_videos('invalid_channel') }.to raise_error(
          Youtube::Errors::NotFoundError,
          /YouTube resource not found/
        )
      end

      it 'handles quota exceeded errors' do
        error = Yt::Errors::RequestError.new('Quota exceeded')
        allow(error).to receive(:reasons).and_return([ 'quotaExceeded' ])
        allow(error).to receive(:response_body).and_return({})
        allow(mock_channel).to receive(:videos).and_raise(error)

        expect { service.get_videos(channel_handle) }.to raise_error(
          Youtube::Errors::QuotaExceededError,
          /YouTube API quota exceeded/
        )
      end

      it 'handles rate limit errors with retry mechanism' do
        call_count = 0
        allow(mock_channel).to receive(:videos) do
          call_count += 1
          if call_count < 3
            error = Yt::Errors::RequestError.new('Rate limit exceeded')
            allow(error).to receive(:reasons).and_return([ 'rateLimitExceeded' ])
            allow(error).to receive(:response_body).and_return({})
            raise error
          else
            mock_videos
          end
        end

        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1 ])
        allow(service).to receive(:sleep)

        result = service.get_videos(channel_handle)
        expect(result[:videos].size).to eq(1)
        expect(call_count).to eq(3)
      end
    end

    context 'with empty results' do
      it 'handles channels with no videos' do
        allow(mock_videos).to receive(:take).with(50).and_return([])

        result = service.get_videos(channel_handle)

        expect(result[:videos]).to eq([])
        expect(result[:pagination][:returned_count]).to eq(0)
      end

      it 'handles offset beyond available videos' do
        allow(mock_videos).to receive(:drop).with(1000).and_return(mock_videos)
        allow(mock_videos).to receive(:take).with(50).and_return([])

        result = service.get_videos(channel_handle, offset: 1000)

        expect(result[:videos]).to eq([])
        expect(result[:pagination][:returned_count]).to eq(0)
      end
    end

    context 'with video data edge cases' do
      it 'handles videos with nil or missing metadata' do
        incomplete_video = double('Yt::Video')
        allow(incomplete_video).to receive(:id).and_return('incomplete_id')
        allow(incomplete_video).to receive(:title).and_return(nil)
        allow(incomplete_video).to receive(:description).and_return('')
        allow(incomplete_video).to receive(:published_at).and_return(nil)
        allow(incomplete_video).to receive(:view_count).and_return(0)
        allow(incomplete_video).to receive(:like_count).and_return(nil)
        allow(incomplete_video).to receive(:duration).and_return(0)
        allow(incomplete_video).to receive_message_chain(:thumbnails, :default, :url).and_return(nil)

        allow(mock_videos).to receive(:take).with(50).and_return([ incomplete_video ])

        result = service.get_videos(channel_handle)

        video = result[:videos].first
        expect(video[:id]).to eq('incomplete_id')
        expect(video[:title]).to be_nil
        expect(video[:description]).to eq('')
        expect(video[:published_at]).to be_nil
        expect(video[:view_count]).to eq(0)
        expect(video[:like_count]).to be_nil
        expect(video[:duration]).to eq(0)
        expect(video[:thumbnail_url]).to be_nil
      end

      it 'handles very long video descriptions' do
        long_description = 'A' * 5000
        allow(mock_video1).to receive(:description).and_return(long_description)
        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1 ])

        result = service.get_videos(channel_handle)

        expect(result[:videos].first[:description]).to eq(long_description)
      end

      it 'handles special characters in video titles and descriptions' do
        special_title = 'Test 🎵 Video "Special" & Characters <tag>'
        special_description = 'Description with émojis 🎶 and spécial çharacters'

        allow(mock_video1).to receive(:title).and_return(special_title)
        allow(mock_video1).to receive(:description).and_return(special_description)
        allow(mock_videos).to receive(:take).with(50).and_return([ mock_video1 ])

        result = service.get_videos(channel_handle)

        video = result[:videos].first
        expect(video[:title]).to eq(special_title)
        expect(video[:description]).to eq(special_description)
      end
    end
  end
end
