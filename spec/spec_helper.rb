# rspec documentation: http://rubydoc.info/gems/rspec-core/frames/file/README.md

require 'rspec'
require 'pp'
require 'money'

# uncomment below to see requests
#require 'net-http-spy'
# uncomment below to set higher verbosity
#Net::HTTP.http_logger_options = {:verbose => true}

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SITE = 'http://local.chargeio.com:8080/'
USE_MOCK = !ENV['site']

RSpec.configure do |c|
  c.before :each do
    #
    #
  end
end

include ChargeIO::Helpers

require 'chargeio'

DEFAULT_MERCHANT_TEST_MODE_OPTIONS = {
  :site => ENV['site'] || SITE,
  :auth_user => ENV['auth_user'] || 'm_wKgFeD0hHlaBPSGgaAQAAA',
  :auth_password => ENV['auth_password'] || 'E39rPZuZnK9716EgreDTGd57cd6ljoMX'
}

DEFAULT_MERCHANT_LIVE_MODE_OPTIONS = {
    :site => ENV['site'] || SITE,
    :auth_user => ENV['auth_user'] || 'm_wKgFeD0hHlaBPSGgaAQAAA',
    :auth_password => ENV['auth_password'] || 'puz9RoLk3u27BzXG6GL1TUF7VFoWplpU'
}

DEFAULT_CARD_PARAMS = {
    type: 'card',
    number: '4242424242424242',
    card_type: 'VISA',
    exp_month: 10,
    exp_year: 2020,
    cvv: 123,
    name: 'Some Customer',
    address1: '123 Main St',
    postal_code: '78730',
    email_address: 'customer@somebidness.com'
}

MC_CARD_PARAMS = {
    type: 'card',
    number: '5499740000000057',
    card_type: 'MASTERCARD',
    exp_month: 12,
    exp_year: 2020,
    cvv: '998',
    name: 'Test Customer',
    address1: '123 N. Main St.',
    address2: 'Apt. 4-D',
    postal_code: '99997-0008',
    email_address: 'mc_user@somebidness.com'
}

DEFAULT_ACH_PARAMS = {
    type: 'bank',
    routing_number: '111000025',
    account_number: '1234567890',
    account_type: 'CHECKING',
    name: 'Some Customer'
}
