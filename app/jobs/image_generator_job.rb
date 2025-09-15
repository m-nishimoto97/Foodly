# app/jobs/image_generator_job.rb
require "open-uri"

class ImageGeneratorJob < ApplicationJob
  queue_as :default

  def perform(id)
    recipe = Recipe.find(id)
    return if recipe.photo.attached?  # idempotency: skip if it's already there

    url  = "https://image.pollinations.ai/prompt/#{ERB::Util.url_encode(recipe.name)}"
    file = URI.open(url, open_timeout: 10, read_timeout: 20)  # basic timeouts

    recipe.photo.attach(
      io: file,
      filename: "#{recipe.id}.png",
      content_type: "image/png"
    )

    recipe.save!

  Turbo::StreamsChannel.broadcast_replace_to(recipe.scan, target: "recipe-photo-#{recipe.id}", partial: "recipes/photo", locals: { recipe: recipe })

    Rails.logger.info("[ImageGeneratorJob] attached photo to recipe=#{recipe.id}")
  rescue => e
    Rails.logger.error("[ImageGeneratorJob] recipe=#{id} #{e.class}: #{e.message}")
  end
end
