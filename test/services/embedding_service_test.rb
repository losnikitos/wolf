require "test_helper"

class EmbeddingServiceTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
    @original_pipeline = EmbeddingService.pipeline
  end

  teardown do
    EmbeddingService.pipeline = @original_pipeline
  end

  test "embed writes embedding from pipeline for project" do
    vector = Array.new(EmbeddingService::DIMENSIONS, 0.5)
    EmbeddingService.pipeline = ->(_text) { vector }

    project = Project.create!(
      notion_page_id: SecureRandom.uuid,
      name: "Beta",
      roles: [ "Designer" ]
    )

    assert EmbeddingService.embed(project)
    project.reload
    assert_equal vector, project.embedding
  end

  test "embed returns false when text is blank" do
    EmbeddingService.pipeline = ->(_text) { raise "should not call pipeline" }

    project = Project.create!(notion_page_id: SecureRandom.uuid, name: "")

    assert_not EmbeddingService.embed(project)
    assert_nil project.reload.embedding
  end

  test "embed uses record embedding_text" do
    vector = Array.new(EmbeddingService::DIMENSIONS, 0.1)
    captured = nil
    EmbeddingService.pipeline = ->(text) { captured = text; vector }

    talk = Talk.create!(
      notion_page_id: SecureRandom.uuid,
      name: "Keynote",
      topic: "Design",
      organizer: "Conf"
    )

    EmbeddingService.embed(talk)
    assert_includes captured, "Keynote"
    assert_includes captured, "Design"
    assert_includes captured, "Conf"
  end
end
