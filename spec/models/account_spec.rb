require 'spec_helper'

describe ChargeIO::MerchantAccount do

  describe "initialize" do

    it "requires :secret_key" do
      lambda do
        ChargeIO::MerchantAccount.new()
      end.should raise_error
    end

    it "accepts :secret_key" do
      lambda do
        ChargeIO::MerchantAccount.new(:secret_key => 'abc')
      end.should_not raise_error
    end

    # it "requires :auth_password" do
    #   lambda do
    #     ChargeIO::MerchantAccount.new(:auth_user => 'foo')
    #   end.should raise_error
    # end

    it "accepts :id, :secret_key" do
      lambda do
        ChargeIO::MerchantAccount.new(:id => 'abc', :secret_key => 'foo')
      end.should_not raise_error
    end

    it "accepts :id, :gateway" do
      lambda do
        ChargeIO::MerchantAccount.new(:id => 'abc', :gateway => ChargeIO::Gateway.new(DEFAULT_MERCHANT_TEST_MODE_OPTIONS.clone))
      end.should_not raise_error
    end

  end


end
