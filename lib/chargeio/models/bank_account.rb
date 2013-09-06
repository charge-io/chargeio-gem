class ChargeIO::BankAccount < ChargeIO::Base

  def merchant
    gateway.merchant
  end

  def primary?
    attributes['primary']
  end

  def transfers
    gateway.transfers(:account_id => id)
  end

  def debit(amount, params={})
    gateway.transfer(amount, params.merge(:account_id => id, :type => 'DEBIT'))
  end

  def credit(amount, params={})
    gateway.transfer(amount, params.merge(:account_id => id, :type => 'CREDIT'))
  end

  def save
    res = gateway.update_bank_account(id, attributes)
    replace(res)
  end
end

