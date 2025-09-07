class ApplicationViewComponent < ViewComponentContrib::Base
  extend Dry::Initializer

  include ComponentHelper
  include ActionView::Helpers::TagHelper if defined?(ActionView)
end
