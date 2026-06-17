class SitemapsController < ApplicationController
  def show
    expires_in 1.hour, public: true if Rails.env.production?

    @urls = sitemap_urls
  end

  private

    def sitemap_urls
      urls = []
      urls << sitemap_entry(root_url, priority: "1.0", changefreq: "weekly")

      urls << sitemap_entry(
        projects_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: Project.active.maximum(:updated_at)
      )
      urls << sitemap_entry(
        clients_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: Client.active.maximum(:updated_at)
      )
      urls << sitemap_entry(
        media_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: MediaAppearance.active.maximum(:updated_at)
      )
      urls << sitemap_entry(
        talks_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: Talk.active.maximum(:updated_at)
      )
      urls << sitemap_entry(
        reviews_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: Review.active.maximum(:updated_at)
      )
      urls << sitemap_entry(
        blog_index_url,
        priority: "0.6",
        changefreq: "weekly",
        lastmod: BlogPost.active.maximum(:updated_at)
      )

      Project.active.find_each do |project|
        urls << sitemap_entry(
          project_url(project),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: project.updated_at
        )
      end

      Client.active.find_each do |client|
        urls << sitemap_entry(
          client_url(client),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: client.updated_at
        )
      end

      MediaAppearance.active.find_each do |appearance|
        urls << sitemap_entry(
          medium_url(appearance),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: appearance.updated_at
        )
      end

      Talk.active.find_each do |talk|
        urls << sitemap_entry(
          talk_url(talk),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: talk.updated_at
        )
      end

      Review.active.find_each do |review|
        urls << sitemap_entry(
          review_url(review),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: review.updated_at
        )
      end

      BlogPost.active.find_each do |post|
        urls << sitemap_entry(
          blog_url(post),
          priority: "0.8",
          changefreq: "monthly",
          lastmod: post.updated_at
        )
      end

      Project::TAG_KINDS.each do |kind|
        tags_for_kind(kind).each do |tag|
          urls << sitemap_entry(
            collection_projects_url(kind: kind, tag: tag),
            priority: "0.6",
            changefreq: "weekly",
            lastmod: Project.active.with_tag(kind, tag).maximum(:updated_at)
          )
        end
      end

      urls
    end

    def tags_for_kind(kind)
      Project.active.pluck(kind).flat_map { |values| Array(values) }.uniq.compact.sort
    end

    def sitemap_entry(loc, priority:, changefreq:, lastmod: nil)
      {
        loc: loc,
        priority: priority,
        changefreq: changefreq,
        lastmod: lastmod
      }
    end
end
