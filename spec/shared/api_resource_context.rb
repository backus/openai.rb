# frozen_string_literal: true

RSpec.shared_context 'an API Resource' do
  let(:client) { described_class.new('sk-123', http: http) }
  let(:http) { class_spy(HTTP) }

  before do
    allow(http).to receive(:post).and_return(response)
    allow(http).to receive(:get).and_return(response)
    allow(http).to receive(:delete).and_return(response)
  end

  let(:response) do
    instance_double(
      HTTP::Response,
      status: HTTP::Response::Status.new(200),
      body: JSON.dump(response_body)
    )
  end
end
