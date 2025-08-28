class ScansController < ApplicationController
  def show
    @scan = Scan.find(params[:id])
  end

  def new
    @scan = Scan.new
  end

  def create
    @scan = current_user.scans.new(scan_params)

    if @scan.save
      chat = RubyLLM.chat
      prompt = <<-PROMPT
        Analyze the image and return ONLY an array of ingredients that clearly appear in the photo.
        The output must be a valid JSON array of strings, e.g. ["pork", "onions", "carrots"].

        Rules:
        - Do NOT use vague categories like "meat", "vegetables", or "fruit".
        - Instead, use the most specific general name possible (e.g. "pork", "chicken", "apple", "cucumber").
        - If you cannot confidently identify an ingredient, DO NOT include it in the array.
        - Do not include brand names.
        - Do not add explanations or extra text — output the array only.
      PROMPT

      response = chat.ask(prompt, with: { image: @scan.photo })
      ingredients = JSON.parse(response.content)
      @scan.ingredients = ingredients
      @scan.save
      redirect_to new_scan_recipe_path(@scan), notice: "Photo uploaded successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def scan_params
    params.require(:scan).permit(:photo)
  end
end
