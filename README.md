# OpenAI.rb

A comprehensive (as of March 25th, 2023) OpenAI API wrapper with built-in support for:

* caching
* tokenization
* response streaming
* a simple chainable abstraction for chats

## Install and Setup

To install, you should be able to do:

```sh
$ gem install openai.rb
```

Usage:

```ruby
require 'openai'

openai = OpenAI.create(ENV.fetch('OPENAI_API_KEY'))
openai.api.chat_completions.create(...)
openai.api.embeddings.create(...)
openai.api.models.list
# etc
```

### Caching

Caching for requests is built-in. The supported caching strategy writes response files in a directory you
specify (I chose to write as separate files since I often want to dig around and see the raw data I'm getting
back).

To enable caching:

```ruby
require 'openai'

# This directory should already exist
cache_dir = Pathname.new('~/.cache/openai')

openai = OpenAI.create(ENV.fetch('OPENAI_API_KEY'), cache: cache_dir)

# Will hit the API:
openai.api.completions.create(model: 'text-davinci-002', prompt: 'Say hi')
# Will reuse the cached response:
openai.api.completions.create(model: 'text-davinci-002', prompt: 'Say hi')
```

NOTE: Delete requests are not cached

To temporarily use the client without caching:

```ruby
openai = OpenAI.create(ENV.fetch('OPENAI_API_KEY'), cache: cache_dir)
openai.without_cache.api.completions.create(...)
```

### Tokens

```ruby
# Get encoder for a model and encode
openai.tokens.for_model('gpt-4').encode('Hello world')

# Get encoder by name
openai.tokens.get('cl100k_base').encode('Hello world')

# Get number of tokens
openai.tokens.for_model('gpt-4').num_tokens('Hello, world!') # => 4
```

### Chat Abstraction

You can use `openai.chat` in order to create a simple chainable chat interface with a model:

```ruby
openai = OpenAI.create(ENV.fetch('OPENAI_API_KEY'))

chat = openai.chat(model: 'gpt-3.5-turbo')

chat =
  chat
  .system('You are a chatbot that talks and acts like scooby doo.')
  .user('Hi how are you doing today?')
  .submit # API call
  .user('Nice. What kind of snacks do you like?')
  .submit # API call

puts chat.to_log_format
```

Which results in this output:

> SYSTEM: You are a chatbot that talks and acts like scooby doo.
>
> USER: Hi how are you doing today?
>
> ASSISTANT: Ruh-roh! Hello there, buddy! Scooby-Dooby-Doo is doing great! How about you, pal?
>
> USER: Nice. What kind of snacks do you like?
>
> ASSISTANT: Ruh-roh! Scooby-Dooby-Doo loves all kinds of snacks, especially Scooby Snacks! They are my favorite! But I also love bones, pizza, hamburgers, and any kind of food that's tasty and yummy. How about you, buddy? Do you have a favorite snack?

## API

### Audio

Transcribing audio:

```ruby
transcription = openai.api.audio.transcribe(
  file: '/path/to/sample.mp3',
  model: 'model-id'
)

transcription.text # => "Imagine the wildest idea that you've ever had..."
```

Translating audio:

```ruby
translation = openai.api.audio.translate(
  file: '/path/to/french/sample.mp3',
  model: 'model-id',
)

translation.text # => "Hello, my name is Wolfgang and I come from Germany. Where are you heading today?"
```

### Chat completions

Generating a chat completion:

```ruby
completion = openai.api.chat_completions.create(
  model: 'gpt-3.5-turbo',
  messages: [
    { role: "user", content: "Hello" }
  ]
)

completion.choices.first.message.content   # => "\n\nHello there, how may I assist you today?"
```

Streaming chat completion responses:

```ruby
completion = openai.api.chat_completions.create(
  model: 'gpt-3.5-turbo',
  messages: [{ role: "user", content: "Hello" }],
  stream: true
) do |completion|
  print completion.choices.first.delta.content
end

# >> "\n\nHello there, how may I assist you today?"
```

### Completions

Generating a completion:

```ruby
completion = openai.api.completions.create(
  model: 'text-davinci-002',
  prompt: 'Hello, world!'
)

completion.id                 # => "cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7"
completion.model              # => "text-davinci-003"
completion.choices.first.text # => "\n\nThis is indeed a test"
```

Streaming responses:

```ruby
completion = openai.api.completions.create(
  model: 'text-davinci-002',
  prompt: 'Say hello world',
  stream: true
) do |completion|
  puts completion.choices.first.text
end

# >> "He"
# >> "llo,"
# >> " world"
# >> "!"
```

### Edits

Creating an edit:

```ruby
edit = openai.api.edits.create(
  model: 'text-davinci-002',
  input: "What day of the wek is it?",
  instruction: "Fix the spelling mistake"
)

edit.object             # => "edit"
edit.choices.first.text # => "What day of the week is it?"
```

### Embeddings

Creating an embedding vector for a given input text:

```ruby
embedding = openai.api.embeddings.create(
  model: 'text-embedding-ada-002',
  input: 'Hello, world!'
)

embedding.object                    # => 'list'
embedding.data.first.object         # => 'embedding'
embedding.data.first.embedding.size # => 1536
```

### Files

Upload a file:

```ruby

file = openai.api.files.create(
  file: '/path/to/file.jsonl',
  purpose: 'fine-tune'
)

file.id        # => 'file-XjGxS3KTG0uNmNOK362iJua3'
file.filename  # => 'sample.jsonl'
file.purpose   # => 'fine-tune'
file.deleted?  # => nil
```

Get a list of files:

```ruby

files = openai.api.files.list

files.data.size   # => 2
files.data.first.filename  # => 'train.jsonl'
```

Fetch a specific file’s information:

```ruby

file = openai.api.files.fetch('file-XjGxS3KTG0uNmNOK362iJua3')

file.filename          # => 'mydata.jsonl'
file.bytes              # => 140
file.created_at         # => 1613779657
file.purpose            # => 'fine-tune'
file.object             # => 'file'
```

Get the contents of a file:

```ruby

response = openai.api.files.get_content('file-XjGxS3KTG0uNmNOK362iJua3')

puts response # => (whatever you uploaded)
```

Delete a file:

```ruby

file = openai.api.files.delete('file-XjGxS3KTG0uNmNOK362iJua3')

file.deleted? # => true
```

### Fine-tunes

Creating a fine tune:

```ruby
fine_tune = openai.api.fine_tunes.create(training_file: 'file-XGinujblHPwGLSztz8cPS8XY')

details.id              # => "ft-AF1WoRqd3aJAHsqc9NY7iL8F"
```

Listing fine tunes:

```ruby
fine_tunes = openai.api.fine_tunes.list

fine_tunes.data.first.id     # => "ft-AF1WoRqd3aJAHsqc9NY7iL8F"
fine_tunes.data.first.status # => "pending"
```


Fetching a fine tune:

```ruby
fine_tune = openai.api.fine_tunes.fetch('ft-AF1WoRqd3aJAHsqc9NY7iL8F')
fine_tune.id                        # => "ft-AF1WoRqd3aJAHsqc9NY7iL8F"
```

Canceling a fine tune:

```ruby

# Canceling a fine tune
fine_tune = openai.api.fine_tunes.cancel('ft-xhrpBbvVUzYGo8oUO1FY4nI7')
fine_tune.id     # => "ft-xhrpBbvVUzYGo8oUO1FY4nI7"
fine_tune.status # => "cancelled"
```

Listing fine tune events:

```ruby
events = openai.api.fine_tunes.list_events('fine-tune-id')
```

### Images

#### Generating Images

Create an image with the specified prompt and size:

```ruby
images = openai.api.images.create(prompt: 'a bird in the forest', size: '512x512')

images.data.first.url # => "https://example.com/image1.png"
```

#### Editing Images

Edit an image with the specified parameters:

```ruby
response = openai.api.images.edit(
  image: '/path/to/some_rgba.png',
  mask: '/path/to/some_rgba_mask.png',
  prompt: 'Draw a red hat on the person in the image',
  n: 1,
  size: '512x512',
  response_format: 'url',
  user: 'user-123'
)

response.created # => 1589478378
response.data.first.url # => "https://..."
```

#### Creating Image Variations

Create image variations of the specified image with the specified parameters:

```ruby
image_variations = openai.api.images.create_variation(
  image: '/path/to/some_rgba.png',
  n: 2,
  size: '512x512',
  response_format: 'url',
  user: 'user123'
)

image_variations.created # => 1589478378
image_variations.data.map(&:url) # => ["https://...", "https://..."]
```

### Models

Listing all models:

```ruby
models = api.models.list

models.data.first.id # => "model-id-0"
models.data.size     # => 3
```

Retrieving a model:

```ruby
model = api.models.fetch('text-davinci-002')

model.id           # => "text-davinci-002"
model.object       # => "model"
model.owned_by     # => "openai"
model.permission   # => ["query", "completions", "models:read", "models:write", "engine:read", "engine:write"]
```

### Moderations

Moderate text:

```ruby
moderation = openai.api.moderations.create(
  input: 'This is a test',
  model: 'text-moderation-001'
)

moderation.id                                        # => "modr-5MWoLO"
moderation.model                                     # => "text-moderation-001"
moderation.results.first.categories.hate             # => false
moderation.results.first.categories.hate_threatening # => true
```
