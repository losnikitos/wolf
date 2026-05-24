class NotionTalksSyncer
  Result = Struct.new(:created, :updated, :unchanged, :skipped, :removed_from_media, keyword_init: true) do
    def total
      created + updated + unchanged + skipped
    end
  end

  PROPERTY_MAP = {
    name: { property: "Name", type: :title },
    topic: { property: "Тема", type: :rich_text },
    location: { property: "Location", type: :rich_text },
    organizer: { property: "Организатор", type: :rich_text },
    talk_date: { property: "Date", type: :date }
  }.freeze

  def initialize(
    client: nil,
    database_id: Talk::NOTION_DATABASE_ID,
    page_content_syncer: NotionPageContentSyncer,
    progress_logger: nil,
    force: false
  )
    @client = client || Notion::Client.new
    @database_id = database_id
    @page_content_syncer = page_content_syncer
    @progress_logger = progress_logger.nil? ? ->(message) { $stdout.puts(message) } : progress_logger
    @force = force
  end

  def call(notion_page_id: nil)
    pages = notion_page_id ? [ fetch_page(notion_page_id) ] : fetch_pages
    records_by_page_id = Talk.where(notion_page_id: pages.map(&:id)).index_by(&:notion_page_id)

    counts = { created: 0, updated: 0, unchanged: 0, skipped: 0 }
    total = pages.size

    log_progress("Found #{total} talks in Notion")

    pages.each_with_index do |page, index|
      record = records_by_page_id[page.id] || Talk.new(notion_page_id: page.id)
      outcome = upsert(record, page)
      counts[outcome] += 1
      log_record_progress(index + 1, total, page, outcome)
    end

    removed_from_media = notion_page_id ? 0 : cleanup_misplaced_media!

    Result.new(**counts, removed_from_media: removed_from_media)
  end

  private

  def upsert(talk, page)
    return :skipped unless @force || needs_sync?(talk, page)

    was_new_record = talk.new_record?

    talk.assign_attributes(attributes_for(page))
    assign_project!(talk, page)
    content_changed = talk.changed?

    talk.last_synced_at = Time.current
    talk.save!
    sync_page_content!(talk, page)

    return :created if was_new_record
    return :updated if content_changed

    :unchanged
  end

  def sync_page_content!(talk, page)
    @page_content_syncer.call(talk, page.id, client: @client)
  end

  def needs_sync?(talk, page)
    return true if talk.new_record?
    return true if talk.page_content_never_synced?

    edited_at = parse_time(page.last_edited_time)
    return true if edited_at.nil? || talk.notion_last_edited_at.nil?

    edited_at > talk.notion_last_edited_at
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
    when :title, :rich_text
      key = type == :title ? "title" : "rich_text"
      Array(property[key]).filter_map { |t| t["plain_text"] }.join.presence
    when :date
      date_obj = property["date"]
      start_on = if date_obj.respond_to?(:start)
        date_obj.start
      else
        date_obj && date_obj["start"]
      end
      Date.parse(start_on) if start_on.present?
    when :relation
      Array(property["relation"]).filter_map { |item| item["id"] }
    end
  end

  def assign_project!(talk, page)
    property = page.properties["Проект"]
    page_ids = extract(property, :relation)
    project = page_ids.present? ? Project.find_by(notion_page_id: page_ids.first) : nil
    talk.project = project
  end

  def cleanup_misplaced_media!
    MediaAppearance.where(notion_page_id: Talk.select(:notion_page_id)).destroy_all.size
  end

  def default_for(_type)
    nil
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
    property = page.properties&.dig("Name")
    title = property && extract(property, :title)
    title.presence || page.id
  end

  def log_progress(message)
    @progress_logger.call(message)
  end
end
