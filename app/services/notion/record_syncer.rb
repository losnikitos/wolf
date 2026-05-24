module Notion
  class RecordSyncer
    SYNCERS = {
      Project => NotionProjectsSyncer,
      Talk => NotionTalksSyncer,
      Review => NotionReviewsSyncer,
      MediaAppearance => NotionMediaAppearancesSyncer
    }.freeze

    ROUTE_TYPES = {
      "projects" => Project,
      "talks" => Talk,
      "reviews" => Review,
      "media" => MediaAppearance
    }.freeze

    class << self
      def sync!(record)
        SYNCERS.fetch(record.class).new(force: true, progress_logger: ->(_message) {}).call(
          notion_page_id: record.notion_page_id
        )
      end

      def find(route_type, slug)
        ROUTE_TYPES.fetch(route_type).friendly.find(slug)
      end

      def route_type_for(record)
        ROUTE_TYPES.key(record.class)
      end
    end
  end
end
