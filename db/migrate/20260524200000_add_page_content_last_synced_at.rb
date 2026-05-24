class AddPageContentLastSyncedAt < ActiveRecord::Migration[8.1]
  def up
    add_column :projects, :page_content_last_synced_at, :datetime
    add_column :media_appearances, :page_content_last_synced_at, :datetime

    say_with_time "marking projects with existing page content as synced" do
      Project.find_each do |project|
        next unless project.body.present? || project.media.attached?

        project.update_columns(page_content_last_synced_at: project.last_synced_at || Time.current)
      end
    end
  end

  def down
    remove_column :media_appearances, :page_content_last_synced_at
    remove_column :projects, :page_content_last_synced_at
  end
end
