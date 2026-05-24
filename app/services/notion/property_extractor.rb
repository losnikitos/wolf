module Notion
  class PropertyExtractor
    def extract(property, type)
      return default_for(type) if property.nil?

      case type
      when :title, :rich_text
        key = type == :title ? "title" : "rich_text"
        Array(property[key]).filter_map { |segment| segment["plain_text"] }.join.presence
      when :select
        property["select"] && property["select"]["name"]
      when :status
        property["status"] && property["status"]["name"]
      when :multi_select
        Array(property["multi_select"]).filter_map { |option| option["name"] }
      when :checkbox
        property["checkbox"] == true
      when :year
        name = property["select"] && property["select"]["name"]
        Integer(name, 10) rescue nil
      when :first_file_url
        file = Array(property["files"]).first
        inner = file && file[file["type"]]
        inner && inner["url"]
      when :date
        date_obj = property["date"]
        start_on = if date_obj.respond_to?(:start)
          date_obj.start
        else
          date_obj && date_obj["start"]
        end
        Date.parse(start_on) if start_on.present?
      when :relation
        Array(property["relation"]).filter_map { |item| item["id"] }
      when :url
        property["url"].presence
      end
    end

    def attributes_for(page, property_map)
      attributes = {
        notion_url: page.url,
        archived: page.archived || page["in_trash"] || false,
        notion_created_at: parse_time(page.created_time),
        notion_last_edited_at: parse_time(page.last_edited_time)
      }

      property_map.each do |column, mapping|
        property = page.properties[mapping[:property]]
        attributes[column] = extract(property, mapping[:type])
      end

      attributes
    end

    def parse_time(value)
      Time.zone.parse(value) if value.present?
    end

    private

    def default_for(type)
      case type
      when :multi_select then []
      when :checkbox then false
      end
    end
  end
end
