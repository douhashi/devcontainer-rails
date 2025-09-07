require 'rails_helper'

RSpec.describe "Root routing", type: :routing do
  describe "GET /" do
    it "routes to contents#index" do
      expect(get: "/").to route_to(controller: "contents", action: "index")
    end
  end

  describe "root_path" do
    it "returns /" do
      expect(root_path).to eq("/")
    end
  end
end
