namespace :embeddings do
  desc "Generate embeddings for all embeddable records"
  task embed: :environment do
    EmbeddingService.embed_all_models.each do |model_class, count|
      puts "#{model_class.name}: #{count} embedded"
    end
  end
end

namespace :projects do
  desc "Generate embeddings for all projects (deprecated: use embeddings:embed)"
  task embed: :environment do
    count = EmbeddingService.embed_all(Project)
    puts "Embedded #{count} projects"
  end
end
