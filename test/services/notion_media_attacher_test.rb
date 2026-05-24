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
end
