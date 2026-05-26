class Avo::Resources::Project < Avo::Resources::ApplicationResource
  self.title = :name
  self.includes = [:client]
end
