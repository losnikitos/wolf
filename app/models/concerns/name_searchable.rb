module NameSearchable
  extend ActiveSupport::Concern

  included do
    scope :matching_name, ->(phrase) {
      phrase = phrase.to_s.strip
      next all if phrase.blank?

      # SQLite only case-folds ASCII (LOWER / COLLATE NOCASE). Match in Ruby so
      # Cyrillic and other scripts are case-insensitive too.
      needle = phrase.downcase
      matching_ids = unscope(:order).pluck(:id, :name).filter_map do |id, name|
        id if name.to_s.downcase.include?(needle)
      end

      where(id: matching_ids)
    }
  end
end
