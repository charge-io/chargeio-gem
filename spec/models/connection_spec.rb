require 'spec_helper'

describe "ChargeIO::Connection" do
  before do
    class Foo
      include ChargeIO::Connection

      def process_response(*args)
        super(*args)
      end
    end
  end

  after do
    Object.send(:remove_const, :Foo)
  end

  describe "#process_response" do
    context "with a 404 response" do
      it "raises an exception with returned error" do
        body = <<-json
        {
          "messages":[
            {
              "context": "TransactionEntity[EnqVCIdWEeKekHS8VXVKFg]",
              "code": "resource_not_found",
              "level": "error",
              "message": "Requested resource not found"
            }
          ]
        }
        json

        response = stub(:code => 404, :body => body)

        foo = Foo.new

        expect {
          foo.process_response(Foo, response)
        }.to raise_exception(ChargeIO::ResourceNotFound)
      end
    end
  end
end

