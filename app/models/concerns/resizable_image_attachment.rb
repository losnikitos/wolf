module ResizableImageAttachment
  FULL_LIMIT = [ 2000, nil ].freeze
  THUMB_LIMIT = [ 1000, 1000 ].freeze
  VARIANT_FORMAT = :webp
  VARIANT_QUALITY = 85

  PROCESSABLE_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/webp
  ].freeze

  SIZES = {
    full: FULL_LIMIT,
    thumb: THUMB_LIMIT
  }.freeze

  module_function

  def processable?(attachment)
    return false unless attachment&.image?

    PROCESSABLE_CONTENT_TYPES.include?(attachment.blob.content_type)
  end

  def variant_for(attachment, size:)
    return attachment unless processable?(attachment)

    limit = SIZES.fetch(size)
    attachment.variant(
      resize_to_limit: limit,
      format: VARIANT_FORMAT,
      saver: { quality: VARIANT_QUALITY }
    )
  end

  def warm_variants!(attachment)
    return 0 unless processable?(attachment)

    warmed = 0
    SIZES.each_key do |size|
      variant_for(attachment, size: size).processed
      warmed += 1
    end
    warmed
  end
end
