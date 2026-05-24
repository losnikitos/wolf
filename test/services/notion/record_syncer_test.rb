require "test_helper"

class Notion::RecordSyncerTest < ActiveSupport::TestCase
  test "maps route types to models and syncers" do
    project = Project.new

    assert_equal "projects", Notion::RecordSyncer.route_type_for(project)
    assert_equal Project, Notion::RecordSyncer::ROUTE_TYPES["projects"]
    assert_equal NotionProjectsSyncer, Notion::RecordSyncer::SYNCERS[Project]
  end
end
