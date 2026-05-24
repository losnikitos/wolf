class NotionProjectsSyncer
  Result = Struct.new(:created, :updated, :unchanged, :skipped, keyword_init: true) do
    def total
      created + updated + unchanged + skipped
    end
  end

  PROPERTY_MAP = {
    name: { property: "Проект", type: :title },
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

  def initialize(
    client: nil,
    database_id: Project::NOTION_DATABASE_ID,
    media_attacher: NotionMediaAttacher,
    block_media_collector: NotionBlockMediaCollector,
    blocks_fetcher: NotionBlocksFetcher,
    body_parser: NotionBodyParser,
    progress_logger: nil,
    force: false
  )
    @client = client || Notion::Client.new
    @database_id = database_id
    @media_attacher = media_attacher
    @block_media_collector = block_media_collector
    @blocks_fetcher = blocks_fetcher
    @body_parser = body_parser
    @progress_logger = progress_logger.nil? ? ->(message) { $stdout.puts(message) } : progress_logger
    @force = force
  end

  def call(notion_page_id: nil)
    pages = notion_page_id ? [ fetch_page(notion_page_id) ] : fetch_pages
    projects_by_page_id = Project.where(notion_page_id: pages.map(&:id)).index_by(&:notion_page_id)

    counts = { created: 0, updated: 0, unchanged: 0, skipped: 0 }
    total = pages.size

    log_progress("Found #{total} projects in Notion")

    pages.each_with_index do |page, index|
      project = projects_by_page_id[page.id] || Project.new(notion_page_id: page.id)
      outcome = upsert(project, page)
      counts[outcome] += 1
      log_record_progress(index + 1, total, page, outcome)
    end

    Result.new(**counts)
  end

  private

  def upsert(project, page)
    return :skipped unless @force || needs_sync?(project, page)

    was_new_record = project.new_record?

    project.assign_attributes(attributes_for(page))
    assign_client!(project, page)
    content_changed = project.changed?

    project.last_synced_at = Time.current
    project.save!
    sync_media!(project, page)

    return :created if was_new_record
    return :updated if content_changed

    :unchanged
  end

  def needs_sync?(project, page)
    return true if project.new_record?

    edited_at = parse_time(page.last_edited_time)
    return true if edited_at.nil? || project.notion_last_edited_at.nil?

    edited_at > project.notion_last_edited_at
  end

  def sync_media!(project, page)
    @media_attacher.attach_cover!(project)

    items = @block_media_collector.call(page.id, client: @client)
    @media_attacher.attach_media!(project, items)
    sync_body!(project, page)
  end

  def sync_body!(project, page)
    blocks = @blocks_fetcher.call(page.id, client: @client)
    project.update!(body: @body_parser.call(blocks))
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
    when :relation
      Array(property["relation"]).filter_map { |item| item["id"] }
    end
  end

  def assign_client!(project, page)
    property = page.properties["Client"]
    page_ids = extract(property, :relation)
    client = page_ids.present? ? Client.find_by(notion_page_id: page_ids.first) : nil
    project.client = client
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

  def fetch_page(page_id)
    @client.page(page_id: page_id)
  end

  def fetch_pages
    pages = []
    @client.database_query(database_id: @database_id, page_size: 100) do |response|
      pages.concat(response.results)
    end
    pages
  end

  def log_record_progress(completed, total, page, outcome)
    label = page_label(page)
    log_progress("[#{completed}/#{total}] #{label} — #{outcome}")
  end

  def page_label(page)
    property = page.properties&.dig("Проект")
    title = property && extract(property, :title)
    title.presence || page.id
  end

  def log_progress(message)
    @progress_logger.call(message)
  end
end
