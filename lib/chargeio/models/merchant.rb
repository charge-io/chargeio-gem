class ChargeIO::Merchant < ChargeIO::Base

  def primary_account
    if attributes['accounts'].present?
      attributes['accounts'].each do |a|
        return ChargeIO::Account.new(a.merge(:gateway => self.gateway, :merchant_id => self.id)) if a['primary']
      end
    end
    nil
  end

  def all_accounts
    list = []
    if attributes['accounts'].present?
      attributes['accounts'].each do |a|
        list << ChargeIO::Account.new(a.merge(:gateway => self.gateway, :merchant_id => self.id))
      end
    end
    list
  end

  def primary_bank_account
    if attributes['bank_accounts'].present?
      attributes['bank_accounts'].each do |a|
        return ChargeIO::BankAccount.new(a.merge(:gateway => self.gateway, :merchant_id => self.id)) if a['primary']
      end
    end
    nil
  end

  def all_bank_accounts
    list = []
    if attributes['bank_accounts'].present?
      attributes['bank_accounts'].each do |a|
        list << ChargeIO::BankAccount.new(a.merge(:gateway => self.gateway, :merchant_id => self.id))
      end
    end
    list
  end

  def save
    res = gateway.update_merchant(attributes)
    replace(res)
  end

  def transfers
    gateway.transfers()
  end

  def charges
    gateway.charges()
  end

  def tokens(reference)
    gateway.tokens(reference)
  end
end
