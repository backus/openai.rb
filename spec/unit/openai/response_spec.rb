# frozen_string_literal: true

RSpec.describe OpenAI::Response do
  before do
    user_class = Class.new(described_class) do
      field :username, path: %i[handle]
    end

    stub_const('OpenAISpec::SampleResponse::User', user_class)

    comment_class = Class.new(described_class) do
      field :body
      field :user, wrapper: OpenAISpec::SampleResponse::User
    end

    stub_const('OpenAISpec::SampleResponse::Comment', comment_class)

    post_class = Class.new(described_class) do
      field :created_at, path: %i[meta birth created]
      field :text
      field :comments, wrapper: OpenAISpec::SampleResponse::Comment
      field :author, wrapper: OpenAISpec::SampleResponse::User
      optional_field :co_author, wrapper: OpenAISpec::SampleResponse::User
      optional_field :subtitle

      # For demonstrating that we can use the instance method without specifying
      # a wrapper class
      define_method(:other_author) do
        optional_field([:co_author])
      end
    end

    stub_const('OpenAISpec::SampleResponse::Post', post_class)
  end

  let(:sample_response) do
    OpenAISpec::SampleResponse::Post.new(sample_response_payload)
  end

  let(:sample_response_payload) do
    {
      meta: {
        birth: {
          created: Time.new(2023).to_i
        }
      },
      text: 'This is a post',
      comments: [
        {
          body: 'This is a comment',
          user: {
            handle: 'alice'
          }
        },
        {
          body: 'This is a spicy comment',
          user: {
            handle: 'bob'
          }
        }
      ],
      author: {
        handle: 'carl'
      }
    }
  end

  context 'when inspecting the response' do
    # Define a smaller response payload so this is less annoying to test
    let(:sample_response_payload) do
      {
        meta: { birth: { created: 1234 } },
        text: 'This is a post',
        comments: [],
        author: { handle: 'carl' }
      }
    end

    before do
      # Mark a field as private so we can prove that the #inspect method
      # should use __send__ in case a response class chooses to make a
      # field private.
      OpenAISpec::SampleResponse::Post.class_eval do
        private(:created_at)
      end
    end

    it 'defines a nice clean inspect method' do
      expect(sample_response.inspect).to eql(
        '#<OpenAISpec::SampleResponse::Post '                           \
          'created_at=1234 '                                            \
          'text="This is a post" '                                      \
          'comments=[] '                                                \
          'author=#<OpenAISpec::SampleResponse::User username="carl"> ' \
          'co_author=nil '                                              \
          'subtitle=nil>'
      )
    end

    it 'tracks the fields on a class for the sake of the #inspect method' do
      expect(OpenAISpec::SampleResponse::Comment.__send__(:field_registry))
        .to eql(%i[body user])
    end
  end

  it 'can parse a JSON response' do
    expect(
      OpenAISpec::SampleResponse::Post.from_json(
        JSON.dump(sample_response_payload)
      )
    ).to eql(sample_response)
  end

  it 'exposes the original payload' do
    expect(sample_response.original_payload).to eql(sample_response_payload)
  end

  it 'deep freezes the original payload' do
    original = sample_response.original_payload
    expect(original).to be_frozen
    expect(original[:comments]).to be_frozen
    expect(original[:comments].first).to be_frozen
    expect(original[:comments].first[:user]).to be_frozen
  end

  describe '.field' do
    it 'exposes the field' do
      expect(sample_response.text).to eql('This is a post')
      expect(sample_response.created_at).to eql(1_672_549_200)
    end

    it 'can expose fields under a different name than the key path' do
      expect(sample_response.author.username).to eql('carl')
    end

    it 'wraps the field if a wrapper is provided' do
      expect(sample_response.author).to eql(
        OpenAISpec::SampleResponse::User.new(handle: 'carl')
      )
    end

    it 'wraps each element in a the wrapper if the value is an array' do
      expect(sample_response.comments).to all(
        be_an_instance_of(OpenAISpec::SampleResponse::Comment)
      )
      expect(sample_response.comments[0].user).to eql(
        OpenAISpec::SampleResponse::User.new(handle: 'alice')
      )
      expect(sample_response.comments[1].user).to eql(
        OpenAISpec::SampleResponse::User.new(handle: 'bob')
      )
    end

    context 'when a required field is not present' do
      let(:sample_response_payload) do
        { meta: { error: 'you did something wrong bro' } }
      end

      it 'raises an error when the field is accessed' do
        expect { sample_response.text }.to raise_error(
          described_class::MissingFieldError, <<~ERROR
            Missing field :text in response payload!
            Was attempting to access value at path `[:text]`.
            Payload: {
              "meta": {
                "error": "you did something wrong bro"
              }
            }
          ERROR
        )

        expect { sample_response.created_at }.to raise_error(
          described_class::MissingFieldError, <<~ERROR
            Missing field :birth in response payload!
            Was attempting to access value at path `[:meta, :birth, :created]`.
            Payload: {
              "meta": {
                "error": "you did something wrong bro"
              }
            }
          ERROR
        )
      end
    end
  end

  describe '.optional_field' do
    it 'does not raise an error when a field is not present' do
      expect(sample_response.co_author).to be_nil
      expect(sample_response.other_author).to be_nil
    end

    context 'when the optional field is present' do
      let(:sample_response_payload) do
        super().merge(co_author: { handle: 'dave' })
      end

      it 'exposes the field' do
        expect(sample_response.co_author.username).to eql('dave')
      end
    end
  end
end
