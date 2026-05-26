class Avo::Resources::Client < Avo::Resources::ApplicationResource
  self.title = :name
  self.includes = [:projects]
end
