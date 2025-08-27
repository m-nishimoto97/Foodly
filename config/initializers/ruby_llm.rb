require 'ruby_llm'

RubyLLM.configure do |config|
  config.openai_api_key = ENV["GITHUB_KEY"]
end
