module NotionBodyHelper
  def render_notion_rich_text(segments)
    safe_join(Array(segments).map { |segment| render_notion_text_segment(segment) })
  end

  def render_notion_blocks(blocks, project:)
    return if blocks.blank?

    safe_join(Array(blocks).map { |block| notion_block_tag(block, project: project) })
  end

  def notion_block_tag(block, project:)
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
              render_notion_blocks(children, project: project)
            ].compact)
          end
        ])
      end
    when "numbered_list_item"
      tag.div(class: "my-1 flex gap-2 pl-1 text-zinc-800") do
        tag.div(class: "min-w-0 flex-1") do
          safe_join([
            render_notion_rich_text(rich_text),
            render_notion_blocks(children, project: project)
          ].compact)
        end
      end
    when "toggle"
      tag.details(class: "my-3 rounded-lg border border-zinc-200/80 bg-zinc-50/50 px-4 py-2") do
        safe_join([
          tag.summary(render_notion_rich_text(rich_text), class: "cursor-pointer font-medium text-zinc-900"),
          tag.div(render_notion_blocks(children, project: project), class: "mt-3 space-y-2")
        ])
      end
    when "image", "video", "file"
      render_notion_media_block(block, project: project)
    when "column_list"
      column_count = block["column_count"].to_i
      column_count = Array(block["columns"]).size if column_count.zero?
      style = column_count.positive? ? "grid-template-columns: repeat(#{column_count}, minmax(0, 1fr));" : nil

      tag.div(class: "my-6 grid gap-6", style: style) do
        safe_join(Array(block["columns"]).map do |column|
          tag.div(render_notion_blocks(column["children"], project: project), class: "min-w-0 space-y-3")
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

  def render_notion_media_block(block, project:)
    attachment = project.media_for_block(block["id"])
    caption = render_notion_rich_text(block["caption"])
    type = block["type"]

    tag.figure(class: "my-6 overflow-hidden rounded-xl bg-zinc-100") do
      media = if attachment&.image?
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
end
