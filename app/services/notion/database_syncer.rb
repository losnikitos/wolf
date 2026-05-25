module Notion
  class DatabaseSyncer
    class << self
      attr_reader :model_class, :database_id, :property_map, :title_property, :entity_label, :sync_page_content

      def configure(model:, database_id:, property_map:, title_property:, entity_label:, sync_page_content: false)
        @model_class = model
        @database_id = database_id
        @property_map = property_map.freeze
        @title_property = title_property
        @entity_label = entity_label
        @sync_page_content = sync_page_content
      end
    end

    Result = SyncResult

    def initialize(
      client: nil,
      database_id: nil,
      page_content_syncer: NotionPageContentSyncer,
      progress_logger: nil,
      force: false
    )
      @client = client || Notion::Client.new
      @database_id = database_id || self.class.database_id
      @page_content_syncer = page_content_syncer if self.class.sync_page_content
      @progress_logger = progress_logger.nil? ? ->(message) { $stdout.puts(message) } : progress_logger
      @force = force
      @property_extractor = PropertyExtractor.new
    end

    def call(notion_page_id: nil)
      pages = notion_page_id ? [ fetch_page(notion_page_id) ] : fetch_pages
      records_by_page_id = self.class.model_class
        .where(notion_page_id: pages.map(&:id))
        .index_by(&:notion_page_id)

      counts = { created: 0, updated: 0, unchanged: 0, skipped: 0 }
      total = pages.size

      log_progress("Found #{total} #{self.class.entity_label} in Notion")

      pages.each_with_index do |page, index|
        record = records_by_page_id[page.id] || self.class.model_class.new(notion_page_id: page.id)
        outcome = upsert(record, page)
        counts[outcome] += 1
        log_record_progress(index + 1, total, page, outcome)
      end

      Result.new(**counts, **after_full_sync(notion_page_id: notion_page_id))
    end

    private

    def upsert(record, page)
      return :skipped unless @force || needs_sync?(record, page)

      was_new_record = record.new_record?

      record.assign_attributes(@property_extractor.attributes_for(page, self.class.property_map))
      assign_relations(record, page)
      content_changed = record.changed?

      record.last_synced_at = Time.current
      record.save!
      sync_page_content!(record, page)

      outcome = if was_new_record
        :created
      elsif content_changed
        :updated
      else
        :unchanged
      end

      enqueue_embedding(record) if %i[created updated].include?(outcome)
      outcome
    end

    def enqueue_embedding(record)
      return unless record.class.column_names.include?("embedding")

      RecordEmbeddingJob.perform_later(record)
    end

    def needs_sync?(record, page)
      return true if record.new_record?
      return true if self.class.sync_page_content && record.page_content_never_synced?

      edited_at = @property_extractor.parse_time(page.last_edited_time)
      return true if edited_at.nil? || record.notion_last_edited_at.nil?

      edited_at > record.notion_last_edited_at
    end

    def assign_relations(_record, _page)
    end

    def sync_page_content!(record, page)
      return unless self.class.sync_page_content

      @page_content_syncer.call(record, page.id, client: @client)
    end

    def after_full_sync(notion_page_id:)
      { removed_from_media: 0 }
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
      property = page.properties&.dig(self.class.title_property)
      title = property && @property_extractor.extract(property, :title)
      title.presence || page.id
    end

    def log_progress(message)
      @progress_logger.call(message)
    end
  end
end
