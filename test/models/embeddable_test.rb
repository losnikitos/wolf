require "test_helper"

class EmbeddableTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
    Talk.delete_all
  end

  test "recommended returns nearest active records excluding self" do
    anchor = create_talk!(name: "Anchor", embedding: unit_vector(0))
    similar = create_talk!(name: "Similar", embedding: unit_vector(0, offset: 0.01))
    different = create_talk!(name: "Different", embedding: unit_vector(1))
    archived = create_talk!(name: "Archived", embedding: unit_vector(0, offset: 0.005), archived: true)

    recommendations = anchor.recommended

    assert_equal 2, recommendations.size
    assert_includes recommendations.map(&:id), similar.id
    assert_includes recommendations.map(&:id), different.id
    assert_not_includes recommendations.map(&:id), anchor.id
    assert_not_includes recommendations.map(&:id), archived.id
  end

  test "recommended returns none without embedding" do
    talk = create_talk!(name: "No vector")

    assert_empty talk.recommended
  end

  test "project embedding_text includes name and tags" do
    project = Project.new(
      name: "Alpha",
      roles: [ "Producer" ],
      deliverables: [ "Space" ],
      directions: [ "Branding" ]
    )

    text = project.embedding_text

    assert_includes text, "Alpha"
    assert_includes text, "Producer"
    assert_includes text, "Space"
    assert_includes text, "Branding"
  end

  private

  def create_talk!(**attrs)
    Talk.create!(
      {
        notion_page_id: SecureRandom.uuid,
        name: "Talk",
        archived: false
      }.merge(attrs)
    )
  end

  def unit_vector(axis, offset: 0.0)
    vector = Array.new(EmbeddingService::DIMENSIONS, 0.0)
    vector[axis] = 1.0 - offset
    vector
  end
end
