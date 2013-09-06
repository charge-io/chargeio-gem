class ChargeIO::Transfer < ChargeIO::Base
  def cancel(params={})
    res = gateway.cancel_transfer(id, params)
    replace(res)
  end
end
