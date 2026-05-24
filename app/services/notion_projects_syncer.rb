class NotionProjectsSyncer
  Result = Struct.new(:created, :updated, :unchanged, keyword_init: true) do
    def total
      created + updated + unchanged
    end
  end

  PROPERTY_MAP = {
    name: { property: "Проект", type: :title },
    client: { property: "Клиент", type: :select },
    status: { property: "Статус", type: :status },
    project_type: { property: "Проекты", type: :select },
    city: { property: "Город", type: :select },
    year: { property: "Год", type: :year },
    cover_url: { property: "Cover", type: :first_file_url },
    favorite: { property: "Избранное", type: :checkbox },
    roles: { property: "Роль", type: :multi_select },
    deliverables: { property: "Результат работ", type: :multi_select },
    directions: { property: "Направление", type: :multi_select }
  }.freeze

  def initialize(client: nil, database_id: Project::NOTION_DATABASE_ID, media_attacher: NotionMediaAttacher)
    @client = client || Notion::Client.new
    @database_id = database_id
    @media_attacher = media_attacher
  end

  def call
    counts = { created: 0, updated: 0, unchanged: 0 }

    @client.database_query(database_id: @database_id, page_size: 100) do |response|
      response.results.each do |page|
        counts[upsert(page)] += 1
      end
    end

    Result.new(**counts)
  end

  private

  def upsert(page)
    project = Project.find_or_initialize_by(notion_page_id: page.id)
    was_new_record = project.new_record?

    project.assign_attributes(attributes_for(page))
    content_changed = project.changed?

    project.last_synced_at = Time.current
    project.save!
    @media_attacher.attach_cover!(project)

    return :created if was_new_record
    return :updated if content_changed

    :unchanged
  end

  def attributes_for(page)
    attributes = {
      notion_url: page.url,
      archived: page.archived || page["in_trash"] || false,
      notion_created_at: parse_time(page.created_time),
      notion_last_edited_at: parse_time(page.last_edited_time)
    }

    PROPERTY_MAP.each do |column, mapping|
      property = page.properties[mapping[:property]]
      attributes[column] = extract(property, mapping[:type])
    end

    attributes
  end

  def extract(property, type)
    return default_for(type) if property.nil?

    case type
    when :title
      Array(property["title"]).filter_map { |t| t["plain_text"] }.join.presence
    when :select
      property["select"] && property["select"]["name"]
    when :status
      property["status"] && property["status"]["name"]
    when :multi_select
      Array(property["multi_select"]).filter_map { |o| o["name"] }
    when :checkbox
      property["checkbox"] == true
    when :year
      name = property["select"] && property["select"]["name"]
      Integer(name, 10) rescue nil
    when :first_file_url
      file = Array(property["files"]).first
      inner = file && file[file["type"]]
      inner && inner["url"]
    end
  end

  def default_for(type)
    case type
    when :multi_select then []
    when :checkbox then false
    end
  end

  def parse_time(value)
    Time.zone.parse(value) if value.present?
  end
end
