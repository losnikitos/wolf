require "test_helper"

class Notion::PropertyExtractorTest < ActiveSupport::TestCase
  setup do
    @extractor = Notion::PropertyExtractor.new
  end

  test "extracts title and select properties" do
    assert_equal "Acme", @extractor.extract(title_property("Acme"), :title)
    assert_equal "Active", @extractor.extract(select_property("Active"), :select)
  end

  test "extracts rich text and date properties" do
    assert_equal "Topic", @extractor.extract(rich_text_property("Topic"), :rich_text)
    assert_equal Date.new(2017, 12, 7), @extractor.extract(date_property("2017-12-07"), :date)
  end

  test "extracts project-specific property types" do
    assert_equal [ "Producer" ], @extractor.extract(multi_select_property([ "Producer" ]), :multi_select)
    assert_equal true, @extractor.extract(checkbox_property(true), :checkbox)
    assert_equal 2018, @extractor.extract(select_property("2018"), :year)
    assert_equal "https://files.notion/cover.png", @extractor.extract(file_property("https://files.notion/cover.png"), :first_file_url)
    assert_equal [ "page-1" ], @extractor.extract(relation_property([ "page-1" ]), :relation)
  end

  test "builds attributes from property map" do
    page = OpenStruct.new(
      url: "https://www.notion.so/page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: "2018-06-02T12:00:00.000Z",
      properties: {
        "Name" => title_property("Acme")
      }
    )

    attributes = @extractor.attributes_for(
      page,
      { name: { property: "Name", type: :title } }
    )

    assert_equal "Acme", attributes[:name]
    assert_equal "https://www.notion.so/page-1", attributes[:notion_url]
    assert_equal false, attributes[:archived]
    assert_equal Time.zone.parse("2018-06-01T12:00:00.000Z"), attributes[:notion_created_at]
  end

  private

  def title_property(text)
    { "title" => [ { "plain_text" => text } ] }
  end

  def rich_text_property(text)
    { "rich_text" => [ { "plain_text" => text } ] }
  end

  def select_property(name)
    { "select" => { "name" => name } }
  end

  def multi_select_property(names)
    { "multi_select" => names.map { |name| { "name" => name } } }
  end

  def checkbox_property(value)
    { "checkbox" => value }
  end

  def date_property(start_on)
    { "date" => { "start" => start_on } }
  end

  def relation_property(ids)
    { "relation" => ids.map { |id| { "id" => id } } }
  end

  def file_property(url)
    {
      "files" => [
        {
          "type" => "file",
          "file" => { "url" => url }
        }
      ]
    }
  end
end
