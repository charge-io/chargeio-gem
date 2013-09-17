require 'spec_helper'

describe 'ACH' do
  before(:all) do
    @gateway = ChargeIO::Gateway.new(DEFAULT_MERCHANT_TEST_MODE_OPTIONS.clone)
  end

  describe 'merchant operations' do
    it 'should find the test ACH account on the merchant' do
      merchant = @gateway.merchant
      merchant.should_not be_nil

      account = merchant.primary_ach_account
      account.should_not be_nil

      accounts = merchant.all_ach_accounts
      accounts.length.should >= 1
    end
  end

  describe 'ach transfers' do
    it 'should create and cancel a new debit' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.clone)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.status.should eq 'CAPTURED'
      t.type.should eq 'DEBIT'
      t.amount.should == 176
      t.currency.should eq 'USD'
      t.method[:routing_number].should eq '******025'
      t.method[:account_number].should eq '******7890'
      t.method[:account_type].should eq 'CHECKING'
      t.method[:fingerprint].should_not be_nil
      t.method[:name].should eq 'Some Customer'

      t.cancel
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.status.should eq 'CANCELED'
    end
    it 'should create a new credit' do
      t = @gateway.merchant.primary_ach_account.credit(Money.new(212, 'USD'), :method => DEFAULT_ACH_PARAMS.clone)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.type.should eq 'CREDIT'
      t.amount.should == 212
      t.currency.should eq 'USD'
    end
    it 'should create a new transfer from a one-time token' do
      token = @gateway.create_token(DEFAULT_ACH_PARAMS.clone)
      token.should_not be_nil
      token.errors.present?.should be false
      token.messages.present?.should be false
      token.id.should_not be_nil

      t = @gateway.merchant.primary_ach_account.debit(123, :method => token.id)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.type.should eq 'DEBIT'
      t.amount.should == 123
      t.currency.should eq 'USD'
      t.method[:routing_number].should eq '******025'
      t.method[:account_number].should eq '******7890'
      t.method[:account_type].should eq 'CHECKING'
      t.method[:fingerprint].should_not be_nil
      t.method[:name].should eq 'Some Customer'

      expect { @gateway.merchant.primary_ach_account.debit(91, :method => token.id) }.to raise_exception(ChargeIO::ResourceNotFound)
    end
    it 'should create a new transfer from a saved bank' do
      bank = @gateway.create_bank(DEFAULT_ACH_PARAMS.clone)
      bank.errors.present?.should be false
      bank.id.should_not be_nil
      bank.fingerprint.should_not be_nil
      bank.bank_name.should eq 'BANK OF AMERICA, N.A.'

      t = @gateway.merchant.primary_ach_account.debit(234, :method => bank.id)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.type.should eq 'DEBIT'
      t.amount.should == 234
      t.currency.should eq 'USD'
      t.method[:routing_number].should eq '******025'
      t.method[:account_number].should eq '******7890'
      t.method[:account_type].should eq 'CHECKING'
      t.method[:fingerprint].should_not be_nil
      t.method[:name].should eq 'Some Customer'

      t = @gateway.merchant.primary_ach_account.credit(201, :method => bank.id)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.type.should eq 'CREDIT'
      t.amount.should == 201

      bank = @gateway.delete_bank(bank.id)
      bank.should_not be_nil

      expect { @gateway.merchant.primary_ach_account.debit(91, :method => bank.id) }.to raise_exception(ChargeIO::ResourceNotFound)
    end
    it 'should create a new saved bank from a one-time token' do
      token = @gateway.create_token(DEFAULT_ACH_PARAMS.clone)
      token.should_not be_nil
      token.errors.present?.should be false
      token.messages.present?.should be false
      token.id.should_not be_nil

      bank = @gateway.create_bank(:token_id => token.id)
      bank.should_not be_nil
      bank.errors.present?.should be false
      bank.id.should_not be_nil
      bank.routing_number.should eq token.routing_number
      bank.account_number.should eq token.account_number
      bank.account_type.should eq token.account_type
      bank.name.should eq token.name

      t = @gateway.merchant.primary_ach_account.credit(211, :method => bank.id)
      t.errors.present?.should be false
      t.id.should_not be_nil
      t.type.should eq 'CREDIT'
      t.amount.should == 211
    end
  end

  describe 'retrieving ach transfers' do
    before(:all) do
      @account_pri = @gateway.merchant.primary_ach_account
      @debit = @account_pri.debit(321, :method => DEFAULT_ACH_PARAMS.clone, :reference => 'Debit of $3.21')
      @credit = @account_pri.credit(1962, :method => DEFAULT_ACH_PARAMS.clone, :reference => 'Credit of $19.62')

      # Wait a second to give the indexer time to process the transfers
      sleep(1)
    end
    it 'should return the transfers created above without specifying account' do
      query = @gateway.transfers
      query.current_page.should == 1
      query.total_pages.should be >= 1
      query.total_entries.should be >= 2
      query.size.should be >= 2

      t = query.find {|t| t.id == @debit.id }
      t.should_not be_nil
      t.type.should eq 'DEBIT'
      t.amount.should == 321
      t.reference.should eq 'Debit of $3.21'
      t.status.should eq 'CAPTURED'

      t = query.find {|t| t.id == @credit.id }
      t.should_not be_nil
      t.type.should eq 'CREDIT'
      t.amount.should == 1962
      t.reference.should eq 'Credit of $19.62'
      t.status.should eq 'CAPTURED'
    end
    it 'should return the transfers created above from the primary account' do
      query = @account_pri.transfers
      query.current_page.should == 1
      query.total_pages.should be >= 1
      query.total_entries.should be >= 2
      query.size.should be >= 2

      t = query.find {|t| t.id == @debit.id }
      t.should_not be_nil

      t = query.find {|t| t.id == @credit.id }
      t.should_not be_nil
    end
  end

  describe 'transfer failures' do
    it 'should decline the transfer (general case)' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000001'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Transfer was declined']
    end
    it 'should decline the transfer (hold)' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000002'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Transfer was declined']
    end
    it 'should decline the transfer as a duplicate' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000003'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Transfer was declined as a duplicate']
    end
    it 'should reject the transfer with an invalid account number' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000004'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Account number is invalid']
    end
    it 'should reject the transfer with an invalid routing number' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:routing_number => '111000026'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Routing number is invalid']
    end
    it 'should reject the transfer due to insufficient funds' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000005'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Transfer was declined due to insufficient funds']
    end
    it 'should reject the transfer due to account not found' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000006'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Account was not found']
    end
    it 'should reject the transfer due to account closed' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000007'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Account is closed']
    end
    it 'should reject the transfer due to account not found' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000008'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Account is frozen']
    end
    it 'should reject the transfer due to limits exceeded' do
      t = @gateway.merchant.primary_ach_account.debit(176, :method => DEFAULT_ACH_PARAMS.merge(:account_number => '1000000009'))
      t.errors.present?.should be true
      t.id.should be_nil
      t.errors['base'].should eq ['Transfer was declined due to limits exceeded']
    end
  end
end