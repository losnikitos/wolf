module ProjectsHelper
  def project_path_for(project, client: nil)
    if client
      scoped_client = project.client || client
      client_project_path(client_slug: scoped_client.slug, project_slug: project.slug)
    else
      project_path(project)
    end
  end

  TAG_LABELS = {
    "roles" => "projects.tags.roles",
    "deliverables" => "projects.tags.deliverables",
    "directions" => "projects.tags.directions"
  }.freeze

  def project_tag_path(kind, tag)
    collection_projects_path(kind: kind, tag: tag)
  end

  def project_tag_kind_label(kind)
    t(TAG_LABELS.fetch(kind))
  end

  def project_collection_title(kind, tag)
    t("projects.collection_title", label: project_tag_kind_label(kind), tag: tag)
  end

  def project_tag_link_class
    "inline-flex rounded-md bg-zinc-100 px-2.5 py-1 text-xs font-medium text-zinc-600 transition hover:bg-zinc-200 hover:text-zinc-800"
  end
end
