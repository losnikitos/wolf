class TelegramExportImporter
  DEFAULT_JSON_PATH = Rails.root.join("telegram/volkdays_export.json")
  DEFAULT_ATTACHMENTS_ROOT = Rails.root.join("telegram/attachments")

  def initialize(json_path: DEFAULT_JSON_PATH, attachments_root: DEFAULT_ATTACHMENTS_ROOT)
    @json_path = Pathname(json_path)
    @attachments_root = Pathname(attachments_root)
  end

  def call
    raise ArgumentError, "Export file not found: #{@json_path}" unless @json_path.exist?

    grouped_messages.each_value do |messages|
      import_group(messages)
    end
  end

  private

  def grouped_messages
    groups = Hash.new { |hash, key| hash[key] = [] }

    channel_messages.each do |message|
      key = message["grouped_id"].presence || message["id"]
      groups[key] << message
    end

    groups
  end

  def channel_messages
    JSON.parse(@json_path.read).filter_map do |entry|
      next unless entry["_"] == "Message" && entry["post"]

      entry
    end
  end

  def import_group(messages)
    messages = messages.sort_by { |message| message["id"] }
    primary = messages.first
    text_message = messages.find { |message| message["message"].to_s.strip.present? }
    telegram_message_id = primary["id"]
    body = text_message&.dig("message").to_s
    entities = text_message&.dig("entities") || []
    poll = extract_poll(messages)

    post = BlogPost.find_or_initialize_by(telegram_message_id: telegram_message_id)
    post.assign_attributes(
      telegram_grouped_id: primary["grouped_id"],
      telegram_message_ids: messages.map { |message| message["id"] },
      title: build_title(body, telegram_message_id),
      body: body.presence,
      entities: entities,
      poll: poll,
      published_at: parse_time(primary["date"]),
      edited_at: parse_time(primary["edit_date"]),
      views: primary["views"],
      reactions: primary["reactions"] || [],
      imported_at: Time.current,
      archived: false
    )
    post.save!

    sync_attachments(post, messages)
  end

  def build_title(body, telegram_message_id)
    return "Post #{telegram_message_id}" if body.blank?

    body.lines.first.to_s.squish.truncate(80)
  end

  def extract_poll(messages)
    poll_message = messages.find { |message| message.dig("media", "_") == "MessageMediaPoll" }
    return if poll_message.blank?

    poll = poll_message.dig("media", "poll")
    return if poll.blank?

    {
      "question" => poll.dig("question", "text"),
      "answers" => Array(poll["answers"]).map { |answer| answer.dig("text", "text") }.compact
    }
  end

  def sync_attachments(post, messages)
    expected = {}

    messages.each_with_index do |message, index|
      path = message["attachment_path"]
      next if path.blank?

      file_path = @attachments_root.join(path)
      unless file_path.exist?
        Rails.logger.warn("[TelegramExportImporter] Missing attachment for message #{message['id']}: #{file_path}")
        next
      end

      expected[message["id"]] = {
        path: file_path,
        position: index,
        content_type: content_type_for(message, file_path)
      }
    end

    purge_stale_attachments(post, expected.keys)

    expected.each do |telegram_message_id, attachment|
      next if attachment_already_attached?(post, telegram_message_id, attachment[:path])

      File.open(attachment[:path], "rb") do |io|
        post.media.attach(
          io: io,
          filename: attachment[:path].basename.to_s,
          content_type: attachment[:content_type],
          metadata: {
            telegram_message_id: telegram_message_id,
            position: attachment[:position]
          }
        )
      end
    end
  end

  def attachment_already_attached?(post, telegram_message_id, file_path)
    post.media_attachments.any? do |attachment|
      attachment.blob.metadata["telegram_message_id"] == telegram_message_id &&
        attachment.blob.filename == file_path.basename.to_s
    end
  end

  def purge_stale_attachments(post, telegram_message_ids)
    post.media_attachments.each do |attachment|
      message_id = attachment.blob.metadata["telegram_message_id"]
      attachment.purge if message_id.present? && telegram_message_ids.exclude?(message_id)
    end
  end

  def content_type_for(message, file_path)
    mime_type = message.dig("media", "document", "mime_type")
    return mime_type if mime_type.present?

    Marcel::MimeType.for(file_path, name: file_path.basename.to_s)
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  end
end
