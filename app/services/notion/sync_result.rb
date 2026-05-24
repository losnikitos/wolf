module Notion
  class SyncResult < Struct.new(:created, :updated, :unchanged, :skipped, :removed_from_media, keyword_init: true)
    def initialize(**attributes)
      super
      self.removed_from_media ||= 0
    end

    def total
      created + updated + unchanged + skipped
    end
  end
end
