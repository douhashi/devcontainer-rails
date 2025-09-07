require 'rails_helper'

RSpec.describe 'Kie::Errors' do
  describe Kie::Errors::ApiError do
    it 'inherits from StandardError' do
      expect(Kie::Errors::ApiError.superclass).to eq(StandardError)
    end

    it 'stores response code and body' do
      error = Kie::Errors::ApiError.new('API Error', 400, 'Bad Request')
      expect(error.message).to eq('API Error')
      expect(error.response_code).to eq(400)
      expect(error.response_body).to eq('Bad Request')
    end

    it 'accepts nil for response_code and response_body' do
      error = Kie::Errors::ApiError.new('API Error')
      expect(error.response_code).to be_nil
      expect(error.response_body).to be_nil
    end
  end

  describe Kie::Errors::AuthenticationError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::AuthenticationError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::AuthenticationError.new
      expect(error.message).to eq('Invalid API key')
    end
  end

  describe Kie::Errors::RateLimitError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::RateLimitError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::RateLimitError.new
      expect(error.message).to eq('Rate limit exceeded')
    end
  end

  describe Kie::Errors::NetworkError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::NetworkError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::NetworkError.new
      expect(error.message).to eq('Network error occurred')
    end
  end

  describe Kie::Errors::TimeoutError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::TimeoutError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::TimeoutError.new
      expect(error.message).to eq('Request timed out')
    end
  end

  describe Kie::Errors::TaskFailedError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::TaskFailedError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::TaskFailedError.new
      expect(error.message).to eq('Task execution failed')
    end
  end

  describe Kie::Errors::InsufficientCreditsError do
    it 'inherits from ApiError' do
      expect(Kie::Errors::InsufficientCreditsError.superclass).to eq(Kie::Errors::ApiError)
    end

    it 'has a default message' do
      error = Kie::Errors::InsufficientCreditsError.new
      expect(error.message).to eq('Insufficient credits')
    end
  end
end
