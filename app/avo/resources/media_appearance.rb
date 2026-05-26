class Avo::Resources::MediaAppearance < Avo::Resources::ApplicationResource
  self.title = :name
  self.translation_key = "avo.resource_translations.media"
  self.includes = [:project]
end
