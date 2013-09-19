class ChargeIO::Transaction < ChargeIO::Base
  def void(params={})
    res = gateway.void(id, params)
    replace(res)
  end
end