module ChargeIO::Connection
  private

  def get(uri, id=nil, params={}, headers={})
    request = HTTParty::Request.new(Net::HTTP::Get,
                                    id.blank? ? "#{self.gateway.url}#{uri}" : "#{self.gateway.url}#{uri}/#{id}",
                                    :headers => headers.merge({'content-type' => 'application/json'}),
                                    :format => :json,
                                    :default_params => params,
                                    :basic_auth => self.gateway.auth)
    request.perform
  end

  def post(uri, params=nil, headers={})
    request = HTTParty::Request.new(Net::HTTP::Post,
                                    "#{self.gateway.url}#{uri}",
                                    :headers => headers.merge({'content-type' => 'application/json'}),
                                    :body => params,
                                    :format => :json,
                                    :basic_auth => self.gateway.auth)
    request.perform
  end

  def form_post(uri, params=nil, headers={})
    params_urlenc = URI.encode_www_form(params)
    request = HTTParty::Request.new(Net::HTTP::Post,
                                    "#{self.gateway.url}#{uri}",
                                    :headers => headers.merge({'content-type' => 'application/x-www-form-urlencoded'}),
                                    :body => params_urlenc,
                                    :format => :plain,
                                    :basic_auth => self.gateway.auth)
    request.perform
  end

  def put(uri, id, params, headers={})
    request = HTTParty::Request.new(Net::HTTP::Put,
                                    id.blank? ? "#{self.gateway.url}#{uri}" : "#{self.gateway.url}#{uri}/#{id}",
                                    :headers => headers.merge({'content-type' => 'application/json'}),
                                    :body => params,
                                    :format => :json,
                                    :basic_auth => self.gateway.auth)
    request.perform
  end

  def delete(uri, id, headers={})
    request = HTTParty::Request.new(Net::HTTP::Delete,
                                    id.blank? ? "#{self.gateway.url}#{uri}" : "#{self.gateway.url}#{uri}/#{id}",
                                    :headers => headers,
                                    #:format => :json,
                                    #:body => '',
                                    :basic_auth => self.gateway.auth)
    request.perform
  end

  def process_list_response(klass, response, key)
    return nil if response.nil? or response.code == 204
    raise ChargeIO::Unauthorized.new "You do not have permissions to access this resource. Please contact ChargeIO for more information" if response.code == 401
    handle_not_found response if response.code == 404
    #handle_invalid_request response if response.code == 400

    attrs = ActiveSupport::JSON.decode(response.body)
    list = attrs['page'].present? ? ChargeIO::Collection.new(attrs['page'],attrs['page_size'],attrs['total_entries']) : []
    if attrs[key].present?
      attrs[key].each do |attributes|
        list << klass.new(attributes.merge(:gateway => self.gateway))
      end
    end
    list
  end

  def process_response(klass, response)
    return nil if response.nil? or response.code == 204
    raise ChargeIO::Unauthorized.new "You do not have permissions to access this resource. Please contact ChargeIO for more information" if response.code == 401
    handle_not_found response if response.code == 404
    #handle_invalid_request response if response.code == 400

    attributes = ActiveSupport::JSON.decode(response.body)
    obj = klass.new attributes.merge(:gateway => gateway)
#    obj.attributes.merge!(attributes.merge(:gateway => gateway))
    mod = Module.new do
      obj.attributes.keys.each do |k|
        next if k == "messages"

        define_method(k) do
          return self.attributes[k]
        end

        define_method("#{k}=") do |val|
          self.attributes[k] = val
        end
      end
    end
    obj.send(:extend, mod)
    obj.process_response_errors(obj.attributes)
    obj
  end

  def handle_not_found(response)
    response_json = ActiveSupport::JSON.decode(response.body)

    if response_json['messages']
      msg = ChargeIO::Message.new response_json['messages'].first
      raise ChargeIO::ResourceNotFound.new msg.context
    end
    raise ChargeIO::ResourceNotFound.new "An error occurred. Please contact ChargeIO for more information"
  end

  def handle_invalid_request(response)
    response_json = ActiveSupport::JSON.decode(response.body)

    if response_json['messages']
      msg = ChargeIO::Message.new response_json['messages'].first
      raise ChargeIO::InvalidRequest.new msg
    end
    raise ChargeIO::InvalidRequest.new "An error occurred. Please contact ChargeIO for more information"
  end
end
