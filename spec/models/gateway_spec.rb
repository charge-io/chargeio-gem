require 'spec_helper'

describe ChargeIO::Gateway do

  describe "initialize" do

    it "requires key" do
      lambda do
        ChargeIO::Gateway.new()
      end.should raise_error
    end

    it "requires password" do
      lambda do
        ChargeIO::Gateway.new(:auth_user => 'foo')
      end.should raise_error
    end

    it "accepts key and password" do
      lambda do
        ChargeIO::Gateway.new(:auth_user => 'foo', :auth_password => 'bar')
      end.should_not raise_error
    end

  end


end
