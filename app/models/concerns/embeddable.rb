module Embeddable
  extend ActiveSupport::Concern

  included do
    has_neighbors :embedding, dimensions: EmbeddingService::DIMENSIONS
  end

  def recommended(limit: 3)
    return self.class.none if embedding.blank?

    nearest_neighbors(:embedding, distance: "cosine")
      .merge(self.class.active)
      .limit(limit)
  end
end
