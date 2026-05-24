module SearchHelper
  def talk_path_for(talk)
    return project_path(talk.project) if talk.project.present?
    return talk.notion_url if talk.notion_url.present?

    nil
  end

  def talk_link_options(talk)
    return {} if talk.project.present?

    { target: "_blank", rel: "noopener noreferrer" }
  end
end
