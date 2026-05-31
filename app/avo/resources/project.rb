class Avo::Resources::Project < Avo::Resources::ApplicationResource
  self.title = :name
  self.includes = [:client]

  def filters
    filter Avo::Filters::ProjectName
  end
end
