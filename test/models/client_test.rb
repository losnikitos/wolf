require "test_helper"

class ClientTest < ActiveSupport::TestCase
  setup do
    Client.delete_all
    Project.delete_all
  end

  test "generates slug from name" do
    client = Client.create!(notion_page_id: SecureRandom.uuid, name: "Все для видеоигр")
    assert_equal "vse-dlya-videoigr", client.slug
  end

  test "projects belong to client" do
    client = Client.create!(notion_page_id: SecureRandom.uuid, name: "Acme")
    project = Project.create!(notion_page_id: SecureRandom.uuid, name: "Launch", client: client)

    assert_equal client, project.client
    assert_includes client.projects, project
  end
end
