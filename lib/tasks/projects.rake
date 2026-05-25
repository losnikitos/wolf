namespace :projects do
  desc "Generate embeddings for all projects (name + tags)"
  task embed: :environment do
    count = 0
    Project.find_each do |project|
      count += 1 if ProjectEmbeddingService.embed(project)
    end
    puts "Embedded #{count} projects"
  end
end
