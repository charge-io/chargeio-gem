class ChargeIO::AchAccount < ChargeIO::Base

  def merchant
    gateway.merchant
  end

  def primary?
    attributes['primary']
  end

  def transactions
    gateway.transactions(:account_id => id)
  end

  def charge(amount, params={})
    gateway.charge(amount, params.merge(:account_id => id))
  end

  def transfer(amount, params={})
    gateway.transfer(amount, params.merge(:account_id => id))
  end

  def save
    res = gateway.update_ach_account(id, attributes)
    replace(res)
  end
end

