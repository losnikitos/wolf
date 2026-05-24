class NotionClientsSyncer
  Result = Struct.new(:created, :updated, :unchanged, :skipped, keyword_init: true) do
    def total
      created + updated + unchanged + skipped
    end
  end

  PROPERTY_MAP = {
    name: { property: "Name", type: :title },
    client_group: { property: "Group", type: :select }
  }.freeze

  def initialize(
    client: nil,
    database_id: Client::NOTION_DATABASE_ID,
    progress_logger: nil,
    force: false
  )
    @client = client || Notion::Client.new
    @database_id = database_id
    @progress_logger = progress_logger.nil? ? ->(message) { $stdout.puts(message) } : progress_logger
    @force = force
  end

  def call(notion_page_id: nil)
    pages = notion_page_id ? [ fetch_page(notion_page_id) ] : fetch_pages
    clients_by_page_id = Client.where(notion_page_id: pages.map(&:id)).index_by(&:notion_page_id)

    counts = { created: 0, updated: 0, unchanged: 0, skipped: 0 }
    total = pages.size

    log_progress("Found #{total} clients in Notion")

    pages.each_with_index do |page, index|
      record = clients_by_page_id[page.id] || Client.new(notion_page_id: page.id)
      outcome = upsert(record, page)
      counts[outcome] += 1
      log_record_progress(index + 1, total, page, outcome)
    end

    Result.new(**counts)
  end

  private

  def upsert(client, page)
    return :skipped unless @force || needs_sync?(client, page)

    was_new_record = client.new_record?

    client.assign_attributes(attributes_for(page))
    content_changed = client.changed?

    client.last_synced_at = Time.current
    client.save!

    return :created if was_new_record
    return :updated if content_changed

    :unchanged
  end

  def needs_sync?(client, page)
    return true if client.new_record?

    edited_at = parse_time(page.last_edited_time)
    return true if edited_at.nil? || client.notion_last_edited_at.nil?

    edited_at > client.notion_last_edited_at
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
    end
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
