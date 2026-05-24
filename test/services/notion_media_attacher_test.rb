require "test_helper"

class NotionMediaAttacherTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(
      notion_page_id: "page-cover",
      name: "Cover test",
      cover_url: "https://files.notion/cover.png"
    )
  end

  test "downloads and attaches cover from notion url" do
    fake_downloader = lambda do |_url|
      [ StringIO.new("fake-png-bytes"), "cover.png", "image/png" ]
    end

    NotionMediaAttacher.attach_cover!(@project, downloader: fake_downloader)

    assert @project.cover.attached?
    assert_equal "image/png", @project.cover.content_type
    assert_equal "https://files.notion/cover.png", @project.cover.blob.metadata["notion_url"]
  end

  test "skips download when notion url unchanged" do
    @project.cover.attach(
      io: StringIO.new("existing"),
      filename: "cover.png",
      content_type: "image/png",
      metadata: { notion_url: @project.cover_url }
    )

    NotionMediaAttacher.attach_cover!(@project, downloader: ->(_url) { flunk "should not download" })

    assert @project.cover.attached?
  end

  test "purges cover when notion url cleared" do
    @project.cover.attach(
      io: StringIO.new("existing"),
      filename: "cover.png",
      content_type: "image/png"
    )
    @project.update!(cover_url: nil)

    NotionMediaAttacher.attach_cover!(@project)

    assert_not @project.cover.attached?
  end

  test "downloads and attaches page media blocks" do
    items = [
      { notion_block_id: "block-1", url: "https://files.notion/one.png", block_type: "image" },
      { notion_block_id: "block-2", url: "https://files.notion/two.mp4", block_type: "video" }
    ]
    fake_downloader = lambda do |url|
      case url
      when "https://files.notion/one.png"
        [ StringIO.new("png"), "one.png", "image/png" ]
      when "https://files.notion/two.mp4"
        [ StringIO.new("mp4"), "two.mp4", "video/mp4" ]
      end
    end

    NotionMediaAttacher.attach_media!(@project, items, downloader: fake_downloader)

    assert_equal 2, @project.media.count
    block_ids = @project.media.map { |attachment| attachment.blob.metadata["notion_block_id"] }
    assert_equal %w[block-1 block-2], block_ids.sort
  end

  test "skips media download when block url unchanged" do
    items = [
      { notion_block_id: "block-1", url: "https://files.notion/one.png", block_type: "image" }
    ]
    @project.media.attach(
      io: StringIO.new("existing"),
      filename: "one.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-1", notion_url: "https://files.notion/one.png" }
    )

    NotionMediaAttacher.attach_media!(@project, items, downloader: ->(_url) { flunk "should not download" })

    assert_equal 1, @project.media.count
  end

  test "purges media removed from notion" do
    @project.media.attach(
      io: StringIO.new("existing"),
      filename: "one.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-old", notion_url: "https://files.notion/old.png" }
    )

    NotionMediaAttacher.attach_media!(@project, [], downloader: ->(_url) { flunk "should not download" })

    assert_equal 0, @project.media.count
  end
end
