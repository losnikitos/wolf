class NotionMediaAttacher
  def self.attach_cover!(project, downloader: nil)
    new(project, downloader: downloader).attach_cover!
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

    io, filename, content_type = fetch(url)
    return unless io

    content_type = normalize_content_type(content_type, filename)
    return unless Project::COVER_CONTENT_TYPES.include?(content_type)

    @project.cover.attach(
      io: io,
      filename: filename,
      content_type: content_type,
      metadata: { notion_url: url }
    )
  end

  private

  def fetch(url)
    return @downloader.call(url) if @downloader

    download(url)
  end

  def download(url)
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

    filename = filename_from(uri, response)
    content_type = response["content-type"]&.split(";")&.first&.strip
    [ StringIO.new(response.body), filename, content_type ]
  rescue StandardError => e
    Rails.logger.warn("[NotionMediaAttacher] Failed to download #{url}: #{e.class} #{e.message}")
    nil
  end

  def filename_from(uri, response)
    if (disposition = response["content-disposition"])
      match = disposition.match(/filename\*?=(?:UTF-8'')?"?([^";\n]+)"?/i)
      return match[1] if match
    end

    basename = File.basename(uri.path)
    basename.presence || "cover"
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
