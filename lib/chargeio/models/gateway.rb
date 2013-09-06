class ChargeIO::Gateway
  include ChargeIO::Connection

  def initialize(options={})
    @site = options[:site] || ChargeIO::DEFAULT_SITE
    @url = URI.join(@site, "/v1/")

    @auth = {
      :username =>options[:auth_user],
      :password => options[:auth_password]
    }
    raise ArgumentError.new("auth_user not set") if @auth[:username].nil?
    raise ArgumentError.new("auth_password not set") if @auth[:password].nil?
  end

  def as_json(options={})
    { 'site' => @site, 'url' => @url }
  end

  # Merchant operations

  def merchant(params={})
    response = get(:merchant, params)
    process_response(ChargeIO::Merchant, response)
  end

  def update_merchant(params={})
    merchant_json = params.to_json
    response = put(:merchant, nil, merchant_json)
    process_response(ChargeIO::Merchant, response)
  end

  def update_account(account_id, params)
    account_json = params.to_json
    response = put(:accounts, account_id, account_json)
    process_response(ChargeIO::Account, response)
  end

  def update_bank_account(account_id, params)
    account_json = params.to_json
    response = put('bank-accounts', account_id, account_json)
    process_response(ChargeIO::BankAccount, response)
  end

  def create_token(params={})
    response = form_post(:tokens, params)
    process_response(ChargeIO::Token, response)
  end

  def find_token(token_id, params={})
    response = get(:tokens, token_id, params)
    process_response(ChargeIO::Token, response)
  end

  def create_card(params={})
    card_json = params.to_json
    response = post(:cards, card_json)
    process_response(ChargeIO::Card, response)
  end

  def delete_card(token)
    response = delete(:cards, token)
    process_response(ChargeIO::Card, response)
  end

  def find_card(token_id, params={})
    response = get(:cards, token_id, params)
    process_response(ChargeIO::Card, response)
  end

  def cards(params={})
    response = get(:cards, nil, params)
    process_list_response(ChargeIO::Card, response, 'results')
  end

  def create_bank(params={})
    bank_json = params.to_json
    response = post(:banks, bank_json)
    process_response(ChargeIO::Bank, response)
  end

  def delete_bank(token)
    response = delete(:banks, token)
    process_response(ChargeIO::Bank, response)
  end

  def find_bank(token_id, params={})
    response = get(:banks, token_id, params)
    process_response(ChargeIO::Bank, response)
  end

  def banks(params={})
    response = get(:banks, nil, params)
    process_list_response(ChargeIO::Bank, response, 'results')
  end


  def charges(params={})
    response = get(:charges, nil, params)
    process_list_response(ChargeIO::Charge, response, 'results')
  end

  def find_charge(transaction_id, params={})
    response = get(:charges, transaction_id, params)
    process_response(ChargeIO::Charge, response)
  end

  def find_refund(refund_id, params={})
    response = get(:refunds, refund_id, params)
    process_response(ChargeIO::Refund, response)
  end

  def authorize(amount, params={})
    headers = {}
    amount_value, amount_currency = amount_to_parts(amount)
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    transaction_params = params.merge(:auto_capture => false, :amount => amount_value, :currency => amount_currency)
    response = post('charges', transaction_params.to_json, headers)
    process_response(ChargeIO::Charge, response)
  end

  def charge(amount, params={})
    headers = {}
    amount_value, amount_currency = amount_to_parts(amount)
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    transaction_params = params.merge(:amount => amount_value, :currency => amount_currency)
    response = post('charges', transaction_params.to_json, headers)
    process_response(ChargeIO::Charge, response)
  end

  def void(transaction_id, params={})
    headers = {}
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    response = post("charges/#{transaction_id}/void", params.to_json, headers)
    process_response(ChargeIO::Charge, response)
  end

  def capture(transaction_id, amount, params={})
    amount_value, amount_currency = amount_to_parts(amount)
    headers = {}
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    transaction_params = params.merge(:amount => amount_value, :currency => amount_currency)
    response = post("charges/#{transaction_id}/capture", transaction_params.to_json, headers)
    process_response(ChargeIO::Charge, response)
  end

  def refund(transaction_id, amount, params={})
    headers = {}
    amount_value, amount_currency = amount_to_parts(amount)
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    transaction_params = params.merge(:amount => amount_value, :currency => amount_currency)
    response = post("charges/#{transaction_id}/refund", transaction_params.to_json, headers)
    process_response(ChargeIO::Refund, response)
  end

  # ACH transfers
  def transfers(params={})
    response = get(:transfers, nil, params)
    process_list_response(ChargeIO::Transfer, response, 'results')
  end

  def find_transfer(transfer_id, params={})
    response = get(:transfers, transfer_id, params)
    process_response(ChargeIO::Transfer, response)
  end

  def transfer(amount, params={})
    headers = {}
    amount_value, amount_currency = amount_to_parts(amount)
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    transfer_params = params.merge(:amount => amount_value, :currency => amount_currency)
    response = post(:transfers, transfer_params.to_json, headers)
    process_response(ChargeIO::Transfer, response)
  end

  def cancel_transfer(transfer_id, params={})
    headers = {}
    if params.has_key?(:ip_address)
      headers['X-Relayed-IP-Address'] = params.delete(:ip_address)
    end
    response = post("transfers/#{transfer_id}/cancel", params.to_json, headers)
    process_response(ChargeIO::Transfer, response)
  end


  def accounts(params={})
    merchant(params).accounts
  end

  def primary_account(params={})
    merchant(params).primary_account
  end

  def gateway
    self
  end

  def site
    @site
  end

  def url
    @url
  end

  def auth
    @auth
  end

  private

  def amount_to_parts(amount)

    if amount.respond_to?(:currency)
      amount_currency = amount.currency.iso_code
    else
      amount_currency = 'USD'
    end

    if amount.respond_to?(:cents)
      amount_value = amount.cents
    else
      amount_value = Integer(amount)
    end

    return amount_value, amount_currency
  end

end
