class ChargeIO::Transaction < ChargeIO::Base
  def void(params={})
    res = gateway.void(id, params)
    replace(res)
  end

  def sign(data, gratuity=nil, format='JSIGNATURE_NATIVE', params={})
    res = gateway.sign(id, data, gratuity, format, params)
    replace(res)
  end
end