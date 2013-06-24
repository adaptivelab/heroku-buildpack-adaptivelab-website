require 'spec_helper'

describe "Jekyll" do
  it "should build jekyll" do
      Hatchet::AnvilApp.new("adaptivelab-website", :buildpack => buildpack).deploy do |app, heroku, output|
        add_database(app, heroku)
        expect(app).to be_deployed
        expect(output).to match("Running: jekyll")
      end
  end
end
