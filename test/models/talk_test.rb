require "test_helper"

class TalkTest < ActiveSupport::TestCase
  test "generates a slug from the name" do
    talk = Talk.create!(
      notion_page_id: "talk-1",
      name: "Модная дискуссия"
    )

    assert_equal "modnaya-diskussiya", talk.slug
  end

  test "talk_year returns the date year" do
    talk = Talk.new(talk_date: Date.new(2017, 12, 7))

    assert_equal 2017, talk.talk_year
  end
end
