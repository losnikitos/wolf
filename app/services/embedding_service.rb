class EmbeddingService
  MODEL = "sentence-transformers/all-MiniLM-L6-v2"
  DIMENSIONS = 384

  EMBEDDABLE_MODELS = [ Project, Talk, MediaAppearance, Review ].freeze

  class << self
    def pipeline
      @pipeline ||= Informers.pipeline("embedding", MODEL)
    end

    def pipeline=(value)
      @pipeline = value
    end

    def embed(record)
      text = record.embedding_text
      return false if text.blank?

      vector = pipeline.(text)
      record.update_column(:embedding, vector)
      true
    end

    def embed_all(model_class)
      count = 0
      model_class.find_each { |record| count += 1 if embed(record) }
      count
    end

    def embed_all_models
      EMBEDDABLE_MODELS.index_with { |model_class| embed_all(model_class) }
    end
  end
end
