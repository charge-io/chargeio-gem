chargeio-gem
============

Ruby gem to access the chargeIO gateway

Installation
-----------

To use the library in your application, add the following to your Gemfile:

    gem 'chargeio', :git => 'git@github.com:charge-io/chargeio-gem.git'

Alternatively, you can download and install the library:

    git clone git://github.com/charge-io/chargeio-gem.git
    cd chargeio-gem
    gem build chargeio.gemspec
    gem install chargeio-x.x.x.gem

Access to the ChargeIO Gateway occurs through an instance of ChargeIO::Gateway. Gateway
objects require credentials to access your merchant data on the ChargeIO servers. You
provide credentials as arguments to the construction of a Gateway instance:

    gateway = ChargeIO::Gateway.new(:auth_user => api_username, :auth_password => api_password)

substituting your ChargeIO API username and the API password for either your live or test
accounts.

With your Gateway instance created, running a basic credit card charge looks like:

    card = {
        type: 'card',
        number: '4242424242424242',
        exp_month: 10,
        exp_year: 2020,
        cvv: 123,
        name: 'Some Customer'
    }
    charge = gateway.charge(100, :method => card, :reference => 'Invoice 12345')
    
Using the ChargeIO.js library for payment tokenization support on your payment page
simplifies the process even more. Just configure the token callback on your page to
POST the amount and the token ID received to your Ruby web application and then
perform the charge:

    amount = ...
    token_id = ...
    charge = gateway.charge(amount, :method => token_id)
    
Documentation
-----------

The latest ChargeIO API documentation is available at https://chargeio.com/docs/merchant/index.html.