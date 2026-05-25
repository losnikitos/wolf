namespace :media do
  namespace :variants do
    desc "Pre-generate full and thumb WebP variants for all image attachments"
    task warm: :environment do
      attachments = []
      attachments += Project.all.filter_map { |record| record.cover if record.cover.attached? }
      [ Project, Talk, MediaAppearance, Review ].each do |model|
        model.find_each do |record|
          attachments.concat(record.media.to_a)
        end
      end

      processable = attachments.select { |attachment| ResizableImageAttachment.processable?(attachment) }
      puts "Warming variants for #{processable.size} image(s)..."

      warmed = 0
      processable.each_with_index do |attachment, index|
        warmed += ResizableImageAttachment.warm_variants!(attachment)
        puts "  [#{index + 1}/#{processable.size}] #{attachment.record_type}##{attachment.record_id} #{attachment.name}" if ((index + 1) % 10).zero?
      end

      puts "Done. Generated #{warmed} variant(s)."
    end
  end
end
