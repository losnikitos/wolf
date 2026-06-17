module TelegramBodyHelper
  ENTITY_TAGS = {
    "MessageEntityBold" => :strong,
    "MessageEntityItalic" => :em,
    "MessageEntityUnderline" => :u,
    "MessageEntityStrike" => :s,
    "MessageEntityCode" => :code,
    "MessageEntityPre" => :pre
  }.freeze

  def render_telegram_body(post)
    parts = []
    parts << render_telegram_text(post.body, post.entities) if post.body.present?
    parts << render_telegram_poll(post.poll) if post.poll.present?
    safe_join(parts.compact)
  end

  def render_telegram_text(text, entities)
    return if text.blank?

    paragraphs_with_offsets(text).map do |paragraph|
      paragraph_entities = entities_for_range(entities, paragraph[:start], paragraph[:text].length)
      render_telegram_paragraph(paragraph[:text], paragraph_entities)
    end.then { |paragraphs| safe_join(paragraphs) }
  end

  def render_telegram_poll(poll)
    return if poll.blank?

    tag.div(class: "my-6 rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-4 dark:border-zinc-700 dark:bg-zinc-900/50") do
      safe_join([
        tag.p(poll["question"], class: "font-medium text-zinc-900 dark:text-zinc-100"),
        tag.ul(class: "mt-3 list-disc space-y-1 pl-5 text-zinc-700 dark:text-zinc-300") do
          safe_join(Array(poll["answers"]).map { |answer| tag.li(answer) })
        end
      ])
    end
  end

  private

  def paragraphs_with_offsets(text)
    paragraphs = []
    index = 0

    text.split(/\n{2,}/, -1).each do |paragraph|
      paragraphs << { text: paragraph, start: index }
      index += paragraph.length + 2
    end

    paragraphs
  end

  def entities_for_range(entities, range_start, range_length)
    range_end = range_start + range_length

    Array(entities).filter_map do |entity|
      entity_start = entity["offset"]
      entity_end = entity_start + entity["length"]
      next unless entity_start < range_end && entity_end > range_start

      overlap_start = [ entity_start, range_start ].max
      overlap_end = [ entity_end, range_end ].min

      entity.merge(
        "offset" => overlap_start - range_start,
        "length" => overlap_end - overlap_start
      )
    end
  end

  def render_telegram_paragraph(paragraph, entities)
    lines = paragraph.split("\n", -1)
    content = safe_join(lines.map.with_index do |line, index|
      separator = index.positive? ? tag.br : nil
      safe_join([ separator, render_telegram_line(line, entities, line_start_in_paragraph(paragraph, index)) ].compact)
    end)

    tag.p(content, class: "my-2 leading-7 text-zinc-800 dark:text-zinc-200")
  end

  def line_start_in_paragraph(paragraph, line_index)
    paragraph.split("\n", -1).first(line_index).join("\n").length + (line_index.positive? ? 1 : 0)
  end

  def render_telegram_line(line, entities, line_start)
    return "" if line.blank?

    segments = segments_for_range(line, entities, line_start)
    safe_join(segments.map { |segment| render_telegram_segment(segment) })
  end

  def segments_for_range(text, entities, text_start)
    text_end = text_start + text.length
    points = [ 0, text.length ]

    Array(entities).each do |entity|
      entity_start = text_start + entity["offset"]
      entity_end = entity_start + entity["length"]
      next unless entity_start < text_end && entity_end > text_start

      points << [ entity_start - text_start, 0 ].max
      points << [ entity_end - text_start, text.length ].min
    end

    points = points.uniq.sort
    segments = []

    points.each_cons(2) do |start_offset, end_offset|
      next if start_offset >= end_offset

      segment_text = slice_by_chars(text, start_offset, end_offset - start_offset)
      next if segment_text.blank?

      covering_entities = Array(entities).select do |entity|
        entity_start = entity["offset"]
        entity_end = entity_start + entity["length"]
        entity_start <= start_offset && entity_end >= end_offset
      end

      segments << { text: segment_text, entities: covering_entities }
    end

    segments.presence || [ { text: text, entities: [] } ]
  end

  def render_telegram_segment(segment)
    text = ERB::Util.html_escape(segment[:text])
    Array(segment[:entities]).reverse_each do |entity|
      text = wrap_entity(text, entity)
    end

    text.html_safe
  end

  def wrap_entity(text, entity)
    case entity["_"]
    when "MessageEntityTextUrl"
      url = entity["url"].to_s
      return text if url.blank?

      link_to(text.html_safe, url, class: tw_text_link_classes, rel: "noopener noreferrer", target: "_blank")
    when "MessageEntityUrl"
      link_to(text.html_safe, text, class: tw_text_link_classes, rel: "noopener noreferrer", target: "_blank")
    when "MessageEntityMention"
      handle = segment_text_for_entity(text).delete_prefix("@")
      link_to(text.html_safe, "https://t.me/#{handle}", class: tw_text_link_classes, rel: "noopener noreferrer", target: "_blank")
    when "MessageEntityHashtag"
      tag.span(text, class: "text-zinc-600 dark:text-zinc-400")
    else
      tag_name = ENTITY_TAGS[entity["_"]]
      return content_tag(tag_name, text.html_safe, class: entity_tag_classes(tag_name)) if tag_name

      text
    end
  end

  def segment_text_for_entity(text)
    text.respond_to?(:to_str) ? text.to_str : text
  end

  def entity_tag_classes(tag_name)
    case tag_name
    when :code
      "rounded bg-zinc-100 px-1 py-0.5 font-mono text-sm text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200"
    when :pre
      "my-3 block overflow-x-auto rounded-lg bg-zinc-100 p-3 font-mono text-sm text-zinc-800 dark:bg-zinc-800 dark:text-zinc-200"
    end
  end

  def slice_by_chars(string, char_offset, char_length)
    string.chars.slice(char_offset, char_length)&.join
  end
end
