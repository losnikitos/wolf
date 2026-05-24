class NotionMediaAttacher
  def self.attach_cover!(project, downloader: nil)
    new(project, downloader: downloader).attach_cover!
  end

  def self.attach_media!(project, items, downloader: nil)
    new(project, downloader: downloader).attach_media!(items)
  end

  def initialize(project, downloader: nil)
    @project = project
    @downloader = downloader
  end

  def attach_cover!
    url = @project.cover_url

    if url.blank?
      @project.cover.purge if @project.cover.attached?
      return
    end

    if @project.cover.attached? && @project.cover.blob.metadata["notion_url"] == url
      return
    end

    attach_file(
      attachment: @project.cover,
      url: url,
      filename_fallback: "cover",
      metadata: { notion_url: url }
    )
  end

  def attach_media!(items)
    desired_block_ids = items.map { |item| item[:notion_block_id] }

    @project.media.each do |attachment|
      block_id = attachment.blob.metadata["notion_block_id"]
      attachment.purge unless desired_block_ids.include?(block_id)
    end

    items.each do |item|
      existing = @project.media.find do |attachment|
        attachment.blob.metadata["notion_block_id"] == item[:notion_block_id]
      end

      if existing && existing.blob.metadata["notion_url"] == item[:url]
        next
      end

      existing&.purge

      attach_file(
        attachment: @project.media,
        url: item[:url],
        filename_fallback: item[:block_type] || "media",
        metadata: {
          notion_block_id: item[:notion_block_id],
          notion_url: item[:url]
        }
      )
    end
  end

  private

  def attach_file(attachment:, url:, filename_fallback:, metadata:)
    io, filename, content_type = fetch(url, filename_fallback: filename_fallback)
    return unless io

    filename = filename.presence || "#{filename_fallback}.bin"
    content_type = normalize_content_type(content_type, filename)
    return unless Project::MEDIA_CONTENT_TYPES.include?(content_type)

    attachment.attach(
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: metadata
    )
  end

  def fetch(url, filename_fallback:)
    return @downloader.call(url) if @downloader

    download(url, filename_fallback: filename_fallback)
  end

  def download(url, filename_fallback:)
    uri = URI.parse(url)
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 30
    ) do |http|
      http.get(uri.request_uri)
    end

    return unless response.is_a?(Net::HTTPSuccess)

    filename = filename_from(uri, response, fallback: filename_fallback)
    content_type = response["content-type"]&.split(";")&.first&.strip
    [ StringIO.new(response.body), filename, content_type ]
  rescue StandardError => e
    Rails.logger.warn("[NotionMediaAttacher] Failed to download #{url}: #{e.class} #{e.message}")
    nil
  end

  def filename_from(uri, response, fallback:)
    if (disposition = response["content-disposition"])
      match = disposition.match(/filename\*?=(?:UTF-8'')?"?([^";\n]+)"?/i)
      return match[1] if match
    end

    basename = File.basename(uri.path)
    basename.presence || fallback
  end

  def normalize_content_type(content_type, filename)
    return content_type if content_type.present? && content_type != "application/octet-stream"

    case File.extname(filename).downcase
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png" then "image/png"
    when ".gif" then "image/gif"
    when ".webp" then "image/webp"
    when ".svg" then "image/svg+xml"
    when ".mp4" then "video/mp4"
    when ".webm" then "video/webm"
    when ".mov" then "video/quicktime"
    else content_type
    end
  end
end
