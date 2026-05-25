require "test_helper"

class ProjectEmbeddingServiceTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
    @original_pipeline = ProjectEmbeddingService.pipeline
  end

  teardown do
    ProjectEmbeddingService.pipeline = @original_pipeline
  end

  test "build_text joins name and tag columns" do
    project = Project.new(
      name: "Alpha",
      roles: [ "Producer" ],
      deliverables: [ "Space" ],
      directions: [ "Branding" ]
    )

    text = ProjectEmbeddingService.build_text(project)

    assert_includes text, "Alpha"
    assert_includes text, "Producer"
    assert_includes text, "Space"
    assert_includes text, "Branding"
  end

  test "embed writes embedding from pipeline" do
    vector = Array.new(ProjectEmbeddingService::DIMENSIONS, 0.5)
    ProjectEmbeddingService.pipeline = ->(_text) { vector }

    project = Project.create!(
      notion_page_id: SecureRandom.uuid,
      name: "Beta",
      roles: [ "Designer" ]
    )

    assert ProjectEmbeddingService.embed(project)
    project.reload
    assert_equal vector, project.embedding
  end

  test "embed returns false when text is blank" do
    ProjectEmbeddingService.pipeline = ->(_text) { raise "should not call pipeline" }

    project = Project.create!(notion_page_id: SecureRandom.uuid, name: "")

    assert_not ProjectEmbeddingService.embed(project)
    assert_nil project.reload.embedding
  end
end
