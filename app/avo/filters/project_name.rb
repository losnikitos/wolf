class Avo::Filters::ProjectName < Avo::Filters::TextFilter
  self.name = "Name"
  self.button_label = "Filter by name"

  def apply(_request, query, value)
    query.matching_name(value)
  end
end
