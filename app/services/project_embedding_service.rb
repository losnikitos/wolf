class ProjectEmbeddingService
  MODEL = "sentence-transformers/all-MiniLM-L6-v2"
  DIMENSIONS = 384

  class << self
    def pipeline
      @pipeline ||= Informers.pipeline("embedding", MODEL)
    end

    def pipeline=(value)
      @pipeline = value
    end

    def build_text(project)
      tags = Array(project.roles) + Array(project.deliverables) + Array(project.directions)
      [ project.name, *tags ].compact_blank.join(" · ")
    end

    def embed(project)
      text = build_text(project)
      return false if text.blank?

      vector = pipeline.(text)
      project.update_column(:embedding, vector)
      true
    end

    def embed_all
      Project.find_each { |project| embed(project) }
    end
  end
end
