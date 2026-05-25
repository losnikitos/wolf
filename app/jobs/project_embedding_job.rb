class ProjectEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(project)
    ProjectEmbeddingService.embed(project)
  end
end
