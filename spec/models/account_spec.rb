require 'spec_helper'

describe ChargeIO::MerchantAccount do

  describe "initialize" do

    it "requires :auth_user" do
      lambda do
        ChargeIO::MerchantAccount.new()
      end.should raise_error
    end

    it "requires :auth_password" do
      lambda do
        ChargeIO::MerchantAccount.new(:auth_user => 'foo')
      end.should raise_error
    end

    it "accepts :id, :auth_user and :auth_password" do
      lambda do
        ChargeIO::MerchantAccount.new(:id => 'abc', :auth_user => 'foo', :auth_password => 'bar')
      end.should_not raise_error
    end

    it "accepts :id, :gateway" do
      lambda do
        ChargeIO::MerchantAccount.new(:id => 'abc', :gateway => ChargeIO::Gateway.new(DEFAULT_MERCHANT_TEST_MODE_OPTIONS.clone))
      end.should_not raise_error
    end

  end


end
