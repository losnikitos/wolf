require "test_helper"

class ProjectRecommendationsTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
  end

  test "recommended_projects returns nearest active projects excluding self" do
    anchor = create_project!(name: "Anchor", embedding: unit_vector(0))
    similar = create_project!(name: "Similar", embedding: unit_vector(0, offset: 0.01))
    different = create_project!(name: "Different", embedding: unit_vector(1))
    archived = create_project!(name: "Archived similar", embedding: unit_vector(0, offset: 0.005), archived: true)

    recommendations = anchor.recommended_projects

    assert_equal 2, recommendations.size
    assert_includes recommendations.map(&:id), similar.id
    assert_includes recommendations.map(&:id), different.id
    assert_not_includes recommendations.map(&:id), anchor.id
    assert_not_includes recommendations.map(&:id), archived.id
  end

  test "recommended_projects returns none without embedding" do
    project = create_project!(name: "No vector")

    assert_empty project.recommended_projects
  end

  private

  def create_project!(**attrs)
    Project.create!(
      {
        notion_page_id: SecureRandom.uuid,
        name: "Project",
        archived: false
      }.merge(attrs)
    )
  end

  def unit_vector(axis, offset: 0.0)
    vector = Array.new(ProjectEmbeddingService::DIMENSIONS, 0.0)
    vector[axis] = 1.0 - offset
    vector
  end
end
