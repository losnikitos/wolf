# frozen_string_literal: true

class Avo::Resources::ApplicationResource < Avo::BaseResource
  abstract_resource!

  DISCOVER_COLUMNS_EXCEPT = %i[embedding].freeze
  DISCOVER_ASSOCIATIONS_EXCEPT = [].freeze

  def fields
    discover_columns except: self.class::DISCOVER_COLUMNS_EXCEPT
    discover_active_storage_attachments
    setup_discovery_options(nil, self.class::DISCOVER_ASSOCIATIONS_EXCEPT, {})
    discover_basic_associations if safe_model_class.respond_to?(:reflections)
  end

  private

  # Field discovery maps ActiveStorage::Attachment reflections (e.g. media_attachments)
  # to :files fields, but Avo's index expects record.media (Attached::Many), not the
  # attachments collection — so we register has_*_attached names directly instead.
  def discover_active_storage_attachments
    return unless model_class.respond_to?(:reflect_on_all_attachments)

    model_class.reflect_on_all_attachments.each do |reflection|
      as_type = reflection.is_a?(ActiveStorage::Reflection::HasOneAttachedReflection) ? :file : :files
      field reflection.name, as: as_type, hide_on: [:index]
    end
  end
end
