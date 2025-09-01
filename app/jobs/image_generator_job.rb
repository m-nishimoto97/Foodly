require "open-uri"

class ImageGeneratorJob < ApplicationJob
  queue_as :default

  def perform(id)
    recipe = Recipe.find(id)
    prompt = generate_prompt(recipe)
    puts (prompt)
    image = RubyLLM.paint(prompt)

    file = if image.url.present?
      URI.open(image.url)
    elsif image.data.present?
      StringIO.new(Base64.decode64(image.data))
    else
      puts "No image returned from RubyLLM"
      return
    end

    recipe.photo.attach(io: file, filename: "#{recipe.id}.png", content_type: "image/png")
    recipe.save
  end

  private

  def generate_prompt(recipe)
    return <<-PROMPT
    You are a precise recipe image generator.
    TASK
    Create a minimalistic dish image for '#{recipe.name}'.
    Use dark black background.
    Flat illustration style, not photorealistic.
    No text, only image.
    PROMPT
  end
end
