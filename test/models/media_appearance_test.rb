require "test_helper"

class MediaAppearanceTest < ActiveSupport::TestCase
  test "generates a slug from the name" do
    appearance = MediaAppearance.create!(
      notion_page_id: "media-1",
      name: "Модная дискуссия"
    )

    assert_equal "modnaya-diskussiya", appearance.slug
  end

  test "appearance_year returns the date year" do
    appearance = MediaAppearance.new(appearance_date: Date.new(2017, 12, 7))

    assert_equal 2017, appearance.appearance_year
  end
end
