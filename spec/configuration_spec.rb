require 'spec_helper'

describe "Rails::Sequel::Configuration" do
  it "should normalize the hash containing 'adapter' => 'postgresql' to 'adapter' => 'postgres'" do
    config = Rails::Sequel::Configuration.new(File.dirname(__FILE__), {"development"=>{"adapter"=>"postgresql"}})
    config.environment_for("development").should == {"adapter"=>"postgres"}
  end
end
