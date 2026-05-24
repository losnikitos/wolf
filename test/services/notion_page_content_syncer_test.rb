require "test_helper"
require "ostruct"

class NotionPageContentSyncerTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(notion_page_id: "page-1", name: "Sample")
  end

  test "syncs body and media attachments from notion blocks" do
    blocks = [
      {
        "id" => "img-1",
        "type" => "image",
        "image" => { "type" => "file", "file" => { "url" => "https://files.notion/photo.png" }, "caption" => [] },
        "children" => []
      },
      {
        "id" => "p-1",
        "type" => "paragraph",
        "paragraph" => { "rich_text" => [ { "plain_text" => "Story", "annotations" => {} } ] },
        "children" => []
      }
    ]
    client = FakeNotionClient.new(blocks)
    fake_downloader = lambda do |url|
      [ StringIO.new("png"), "photo.png", "image/png" ] if url == "https://files.notion/photo.png"
    end

    NotionPageContentSyncer.new(
      @project,
      "page-1",
      client: client,
      media_attacher: media_attacher_with(downloader: fake_downloader)
    ).call

    @project.reload
    assert_equal 2, @project.body.size
    assert_equal "Story", @project.body.last["rich_text"].first["text"]
    assert_equal 1, @project.media.count
    assert_equal "img-1", @project.media.first.blob.metadata["notion_block_id"]
    assert_not_nil @project.page_content_last_synced_at
  end

  test "stores external video embed url in body without downloading" do
    blocks = [
      {
        "id" => "video-1",
        "type" => "video",
        "video" => {
          "type" => "external",
          "external" => { "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
        },
        "children" => []
      }
    ]
    client = FakeNotionClient.new(blocks)

    NotionPageContentSyncer.new(
      @project,
      "page-1",
      client: client,
      media_attacher: media_attacher_with(downloader: ->(_url) { flunk "should not download embeds" })
    ).call

    @project.reload
    assert_equal 1, @project.body.size
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", @project.body.first["embed_url"]
    assert_equal 0, @project.media.count
  end

  private

  def media_attacher_with(downloader:)
    attacher = Object.new
    attacher.define_singleton_method(:attach_cover!) { |*| }
    attacher.define_singleton_method(:attach_media!) do |record, items|
      NotionMediaAttacher.attach_media!(record, items, downloader: downloader)
    end
    attacher
  end

  class FakeNotionClient
    def initialize(blocks)
      @blocks = blocks
    end

    def block_children(**_options)
      yield OpenStruct.new(results: @blocks)
    end
  end
end
