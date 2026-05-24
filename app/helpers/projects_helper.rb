module ProjectsHelper
  def project_path_for(project, client: nil)
    if client
      client_project_path(client_slug: client.slug, project_slug: project.slug)
    else
      project_path(project)
    end
  end

  TAG_LABELS = {
    "roles" => "Roles",
    "deliverables" => "Deliverables",
    "directions" => "Directions"
  }.freeze

  def project_tag_path(kind, tag)
    collection_projects_path(kind: kind, tag: tag)
  end

  def project_tag_kind_label(kind)
    TAG_LABELS.fetch(kind)
  end

  def project_collection_title(kind, tag)
    "#{project_tag_kind_label(kind)}: #{tag}"
  end

  def project_tag_link_class
    "rounded-lg bg-zinc-50 px-3 py-1.5 text-sm text-zinc-700 ring-1 ring-inset ring-zinc-200/80 transition hover:bg-zinc-100 hover:text-zinc-900"
  end
end
