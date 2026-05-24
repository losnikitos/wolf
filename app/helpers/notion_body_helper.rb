module NotionBodyHelper
  def render_notion_rich_text(segments)
    safe_join(Array(segments).map { |segment| render_notion_text_segment(segment) })
  end

  def render_notion_blocks(blocks, record:)
    return if blocks.blank?

    safe_join(Array(blocks).map { |block| notion_block_tag(block, record: record) })
  end

  def notion_block_tag(block, record:)
    type = block["type"]
    id = block["id"]
    rich_text = block["rich_text"]
    children = block["children"]

    case type
    when "heading_1"
      tag.h1(render_notion_rich_text(rich_text), id: id, class: "mt-10 mb-2 text-3xl font-bold tracking-tight text-zinc-900 first:mt-0")
    when "heading_2"
      tag.h2(render_notion_rich_text(rich_text), id: id, class: "mt-8 mb-2 text-2xl font-semibold tracking-tight text-zinc-900 first:mt-0")
    when "heading_3"
      tag.h3(render_notion_rich_text(rich_text), id: id, class: "mt-6 mb-1 text-xl font-semibold text-zinc-900 first:mt-0")
    when "quote"
      tag.blockquote(class: "my-4 border-l-4 border-zinc-300 pl-4 text-zinc-700 italic") do
        render_notion_rich_text(rich_text)
      end
    when "callout"
      tag.aside(class: "my-4 flex gap-3 rounded-lg bg-zinc-50 px-4 py-3 text-zinc-800 ring-1 ring-inset ring-zinc-200/80") do
        safe_join([
          tag.span("💡", class: "text-lg leading-none", aria: { hidden: true }),
          tag.div(render_notion_rich_text(rich_text), class: "min-w-0 flex-1")
        ])
      end
    when "bulleted_list_item"
      tag.div(class: "my-1 flex gap-2 pl-1 text-zinc-800") do
        safe_join([
          tag.span("•", class: "mt-2.5 shrink-0 text-zinc-400", aria: { hidden: true }),
          tag.div(class: "min-w-0 flex-1") do
            safe_join([
              render_notion_rich_text(rich_text),
              render_notion_blocks(children, record: record)
            ].compact)
          end
        ])
      end
    when "numbered_list_item"
      tag.div(class: "my-1 flex gap-2 pl-1 text-zinc-800") do
        tag.div(class: "min-w-0 flex-1") do
          safe_join([
            render_notion_rich_text(rich_text),
            render_notion_blocks(children, record: record)
          ].compact)
        end
      end
    when "toggle"
      tag.details(class: "my-3 rounded-lg border border-zinc-200/80 bg-zinc-50/50 px-4 py-2") do
        safe_join([
          tag.summary(render_notion_rich_text(rich_text), class: "cursor-pointer font-medium text-zinc-900"),
          tag.div(render_notion_blocks(children, record: record), class: "mt-3 space-y-2")
        ])
      end
    when "image", "video", "file"
      render_notion_media_block(block, record: record)
    when "column_list"
      column_count = block["column_count"].to_i
      column_count = Array(block["columns"]).size if column_count.zero?
      style = column_count.positive? ? "grid-template-columns: repeat(#{column_count}, minmax(0, 1fr));" : nil

      tag.div(class: "my-6 grid gap-6", style: style) do
        safe_join(Array(block["columns"]).map do |column|
          tag.div(render_notion_blocks(column["children"], record: record), class: "min-w-0 space-y-3")
        end)
      end
    else
      tag.p(render_notion_rich_text(rich_text), class: "my-2 leading-7 text-zinc-800")
    end
  end

  private

  def render_notion_text_segment(segment)
    text = h(segment["text"])
    href = segment["href"]

    classes = []
    classes << "font-semibold" if segment["bold"]
    classes << "italic" if segment["italic"]
    classes << "underline" if segment["underline"]
    classes << "line-through" if segment["strikethrough"]
    classes << "rounded bg-zinc-100 px-1 py-0.5 font-mono text-sm text-zinc-800" if segment["code"]

    content = tag.span(text, class: classes.presence)

    if href.present?
      link_to content, href, target: "_blank", rel: "noopener noreferrer", class: "text-blue-600 underline decoration-blue-600/40 underline-offset-2 hover:decoration-blue-600"
    else
      content
    end
  end

  def render_notion_media_block(block, record:)
    attachment = record.media_for_block(block["id"])
    caption = render_notion_rich_text(block["caption"])
    type = block["type"]
    embed_url = block["embed_url"]

    tag.figure(class: "my-6 overflow-hidden rounded-xl bg-zinc-100") do
      media = if embed_url.present?
        render_notion_embed(embed_url)
      elsif attachment&.image?
        image_tag attachment, alt: "", class: "w-full object-cover"
      elsif attachment&.video?
        video_tag url_for(attachment), controls: true, playsinline: true, class: "w-full"
      elsif type == "image" && attachment.nil?
        tag.div("Image unavailable", class: "flex aspect-video items-center justify-center text-sm text-zinc-400")
      end

      safe_join([
        media,
        caption.present? ? tag.figcaption(caption, class: "px-4 py-3 text-sm text-zinc-500") : nil
      ].compact)
    end
  end

  def render_notion_embed(url)
    youtube_src = youtube_embed_url(url)
    if youtube_src
      tag.div(class: "aspect-video") do
        tag.iframe(
          src: youtube_src,
          title: "Embedded video",
          class: "h-full w-full",
          allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
          allowfullscreen: true,
          loading: "lazy",
          referrerpolicy: "strict-origin-when-cross-origin"
        )
      end
    else
      link_to url, url, target: "_blank", rel: "noopener noreferrer", class: "flex aspect-video items-center justify-center text-sm font-medium text-zinc-600 underline"
    end
  end

  def youtube_embed_url(url)
    uri = URI.parse(url)
    video_id = case uri.host
    when "www.youtube.com", "youtube.com", "m.youtube.com"
      if uri.path == "/watch"
        URI.decode_www_form(uri.query.to_s).to_h["v"]
      elsif uri.path.start_with?("/embed/", "/shorts/")
        uri.path.split("/").last
      end
    when "youtu.be"
      uri.path.delete_prefix("/").presence
    end

    return if video_id.blank?

    "https://www.youtube.com/embed/#{video_id}"
  rescue URI::InvalidURIError
    nil
  end
end
