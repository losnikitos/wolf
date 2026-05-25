class MediaController < ApplicationController
  def index
    appearances = MediaAppearance.active.ordered
    @appearances_by_publication = appearances.group_by { |appearance| appearance.publication.presence || "Unknown" }
    @publication_names = @appearances_by_publication.keys.sort_by do |name|
      [ -@appearances_by_publication[name].size, name == "Unknown" ? 1 : 0, name ]
    end
  end

  def show
    @media_appearance = MediaAppearance.friendly.find(params[:slug])
    @recommended_media_appearances = @media_appearance.recommended
  end
end
