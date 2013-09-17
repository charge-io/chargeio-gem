require 'spec_helper'

describe "Transaction" do
  before(:all) do
    @gateway = ChargeIO::Gateway.new(DEFAULT_MERCHANT_TEST_MODE_OPTIONS.clone)
    @gateway_live = ChargeIO::Gateway.new(DEFAULT_MERCHANT_LIVE_MODE_OPTIONS.clone)
    @card_params = DEFAULT_CARD_PARAMS.clone
  end

  describe 'capture' do
    before :each do
      @authorized = @gateway.authorize(100, :method => @card_params, :reference => 'auth ref 100')
      @authorized.errors.present?.should be false
      @authorized.id.should_not be_nil
      @authorized.status.should == 'AUTHORIZED'
      @authorized.method[:fingerprint].should_not be_nil
      @authorized.auto_capture.should eq false
    end

    describe 'capture full' do
      it 'should be successful' do
        @authorized.capture(100, :reference => 'cap ref 100')
        @authorized.errors.present?.should be false
        @authorized.messages.present?.should be false
        @authorized.status.should == 'SETTLED'
        @authorized.amount.should == 100
        @authorized.reference.should eq 'auth ref 100'
        @authorized.capture_reference.should eq 'cap ref 100'
      end
    end

    describe 'capture partial' do
      it 'should be successful' do
        @authorized.capture(96)
        @authorized.errors.present?.should be false
        @authorized.messages.present?.should be false
        @authorized.status.should == 'SETTLED'
        @authorized.amount.should == 96
      end
    end

    describe 'failures' do
      it 'should return exceeds_authorized_amount' do
        @authorized.capture(101)
        @authorized.errors.present?.should be true
        @authorized.errors['base'].should == [ 'Amount to capture exceeds the authorized amount' ]
      end
      it 'should return currency_mismatch' do
        @authorized.capture(Money.new(90, 'GBP'))
        @authorized.errors.present?.should be true
        @authorized.errors['base'].should == [ "Specified currency does not match the transaction's currency" ]
      end
      it 'should return not_valid_for_auto_capture' do
        t = @gateway.charge(100, :method => @card_params)
        t.capture
        t.errors.present?.should be true
        t.errors['base'].should == [ 'The operation is unavailable for the transaction' ]
      end
      it 'should return not_valid_for_transaction_status' do
        @authorized.capture
        @authorized.errors.present?.should be false
        @authorized.capture
        @authorized.errors.present?.should be true
        @authorized.errors['base'].should == [ 'The operation cannot be completed in the current status' ]
      end
    end
  end

  describe 'void' do
    before :each do
      @authorized = @gateway.authorize(100, :method => @card_params)
    end

    it 'should succeed' do
      @authorized.void
      @authorized.errors.present?.should be false
      @authorized.status.should == 'VOIDED'
    end

    it 'should succeed' do
      @authorized.void(:reference => 'cancel ref')
      @authorized.errors.present?.should be false
      @authorized.status.should == 'VOIDED'
      @authorized.void_reference.should eq 'cancel ref'
    end

    describe 'failures' do
      it 'should return not_valid_for_auto_capture' do
        t = @gateway.charge(100, :method => @card_params)
        t.void
        t.errors.present?.should be true
        t.errors['base'].should == [ 'The operation is unavailable for the transaction' ]
      end
      it 'should return not_valid_for_transaction_status' do
        @authorized.void
        @authorized.errors.present?.should be false
        @authorized.void
        @authorized.errors.present?.should be true
        @authorized.errors['base'].should == [ 'The operation cannot be completed in the current status' ]
      end
    end
  end

  describe 'refund' do
    describe 'on charged' do
      before :each do
        @authorized = @gateway.charge(100, :method => @card_params)
      end

      describe 'full refund' do
        it 'should be successful' do
          refund = @authorized.refund(100, :reference => 'refund ref')
          refund.id.should_not be_nil
          refund.errors.present?.should be false
          refund.messages.present?.should be false
          refund.amount.should == 100
          refund.reference.should eq 'refund ref'
          refund.type.should eq 'REFUND'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 100
        end
      end

      describe 'partial refunds' do
        it 'should be successful' do
          refund = @authorized.refund(50)
          refund.id.should_not be_nil
          refund.errors.present?.should be false
          refund.messages.present?.should be false
          refund.amount.should == 50
          refund.type.should eq 'REFUND'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 50

          refund2 = @authorized.refund(40, :reference => 'partial refund 40')
          refund2.id.should_not be_nil
          refund2.errors.present?.should be false
          refund2.messages.present?.should be false
          refund2.amount.should == 40
          refund2.reference.should eq 'partial refund 40'
          refund2.type.should eq 'REFUND'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 90
        end
      end

      describe 'failures' do
        it 'should return currency_mismatch' do
          refund = @authorized.refund(Money.new(90, 'GBP'))
          refund.errors.present?.should be true
          refund.errors['base'].should == [ "Specified currency does not match the transaction's currency" ]
        end
        it 'should return refund_exceeds_transaction' do
          refund = @authorized.refund(Money.new(101, 'USD'))
          refund.errors.present?.should be true
          refund.errors['base'].should == [ 'Amount of refund exceeds remaining transaction balance' ]
        end
      end
    end
  end

  describe 'credit' do
    describe 'on charged' do
      before :each do
        @authorized = @gateway.charge(100, :method => @card_params)
      end

      describe 'full credit' do
        it 'should be successful' do
          credit = @authorized.refund(100, :method => @card_params.merge(:number => '378282246310005', :card_type => 'AMERICAN_EXPRESS'), :reference => 'credit ref')
          credit.errors.present?.should be false
          credit.messages.present?.should be false
          credit.id.should_not be_nil
          credit.amount.should == 100
          credit.reference.should eq 'credit ref'
          credit.method[:fingerprint].should_not be_nil
          credit.type.should eq 'CREDIT'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 100
        end
      end

      describe 'partial credits' do
        it 'should be successful' do
          credit = @authorized.refund(50, :method => @card_params.merge(:number => '378282246310005', :card_type => 'AMERICAN_EXPRESS'))
          credit.errors.present?.should be false
          credit.messages.present?.should be false
          credit.id.should_not be_nil
          credit.amount.should == 50
          credit.type.should eq 'CREDIT'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 50

          credit2 = @authorized.refund(35, :method => @card_params.merge(:number => '378282246310005', :card_type => 'AMERICAN_EXPRESS'), :reference => 'credit 35')
          credit2.errors.present?.should be false
          credit2.messages.present?.should be false
          credit2.id.should_not be_nil
          credit2.amount.should == 35
          credit2.reference.should eq 'credit 35'
          credit2.type.should eq 'CREDIT'

          charge = @gateway.find_charge(@authorized.id)
          charge.should_not be_nil
          charge.amount_refunded.should == 85
        end
      end

      describe 'credit via payment token' do
        it 'should be successful' do
          token = @gateway.create_token(@card_params.merge(:number => '378282246310005', :card_type => 'AMERICAN_EXPRESS'))
          credit = @authorized.refund(100, :method => token.id, :reference => 'Credit via Token')
          credit.errors.present?.should be false
          credit.messages.present?.should be false
          credit.id.should_not be_nil
          credit.amount.should == 100
          credit.type.should eq 'CREDIT'
          credit.reference.should eq 'Credit via Token'
          credit.method[:card_type].should == 'AMERICAN_EXPRESS'
          credit.method[:number].should == '***********0005'
        end
      end

      describe 'failures' do
        it 'should return card number not_blank' do
          credit = @authorized.refund(50, :method => @card_params.merge(:number => ''))
          credit.errors.present?.should be true
          credit.errors['method.number'].should == [ 'Card number cannot be blank' ]
        end
        it 'should return currency_mismatch' do
          credit = @authorized.refund(Money.new(90, 'GBP'), :method => @card_params)
          credit.errors.present?.should be true
          credit.errors['base'].should == [ "Specified currency does not match the transaction's currency" ]
        end
        it 'should return refund_exceeds_transaction' do
          credit = @authorized.refund(Money.new(101, 'USD'), :method => @card_params)
          credit.errors.present?.should be true
          credit.errors['base'].should == [ 'Amount of refund exceeds remaining transaction balance' ]
        end
      end
    end
  end
end
