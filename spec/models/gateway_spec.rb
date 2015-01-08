require 'spec_helper'

describe ChargeIO::Gateway do

  describe "initialize" do

    it "requires secret_key" do
      lambda do
        ChargeIO::Gateway.new()
      end.should raise_error
    end

    it "accepts secret_key" do
      lambda do
        ChargeIO::Gateway.new(:secret_key => 'foo')
      end.should_not raise_error
    end

    # it "requires password if :auth_user passed" do
    #   lambda do
    #     ChargeIO::Gateway.new(:auth_user => 'foo')
    #   end.should raise_error
    # end


  end


end
