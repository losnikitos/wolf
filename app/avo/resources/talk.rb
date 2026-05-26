class Avo::Resources::Talk < Avo::Resources::ApplicationResource
  self.title = :name
  self.includes = [:project]
end
