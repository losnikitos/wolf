class RecordEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(record)
    EmbeddingService.embed(record)
  end
end
