require "test_helper"

class ResizableImageAttachmentTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(notion_page_id: SecureRandom.uuid, name: "Variant test")
  end

  test "processable? is true for jpeg png and webp" do
    %w[image/jpeg image/png image/webp].each do |content_type|
      attachment = attach_image(content_type: content_type)
      assert ResizableImageAttachment.processable?(attachment), content_type
    end
  end

  test "processable? is false for svg gif and video" do
    {
      "image/svg+xml" => "icon.svg",
      "image/gif" => "animation.gif",
      "video/mp4" => "clip.mp4"
    }.each do |content_type, filename|
      attachment = attach_image(content_type: content_type, filename: filename)
      assert_not ResizableImageAttachment.processable?(attachment), content_type
    end
  end

  test "variant_for returns variant for processable images" do
    attachment = attach_image
    result = ResizableImageAttachment.variant_for(attachment, size: :thumb)

    assert_kind_of ActiveStorage::VariantWithRecord, result
    assert_equal ResizableImageAttachment::THUMB_LIMIT, result.variation.transformations[:resize_to_limit]
  end

  test "variant_for returns original attachment for non-processable images" do
    attachment = attach_image(content_type: "image/gif", filename: "animation.gif")
    result = ResizableImageAttachment.variant_for(attachment, size: :full)

    assert_equal attachment, result
  end

  test "warm_variants! generates webp variants within size limits" do
    skip "libvips not available" unless vips_available?

    attachment = attach_image
    warmed = ResizableImageAttachment.warm_variants!(attachment)

    assert_equal 2, warmed

    ResizableImageAttachment::SIZES.each do |size, limit|
      variant = ResizableImageAttachment.variant_for(attachment, size: size).processed
      assert_equal "image/webp", variant.content_type

      image = Vips::Image.new_from_buffer(variant.download, "")
      assert_operator image.width, :<=, limit[0]
      assert_operator image.height, :<=, limit[1] if limit[1]
    end
  end

  private

  def attach_image(content_type: "image/png", filename: "sample.png")
    @project.media.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: filename,
      content_type: content_type,
      identify: false
    )
    @project.media.last
  end

  def vips_available?
    require "vips"
    true
  rescue LoadError
    false
  end
end
