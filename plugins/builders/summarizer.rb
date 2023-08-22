class Builders::Summarizer < SiteBuilder
  def build
    define_resource_method :summary_extension_output do
      return "<p>#{data[:summary]}</p>" if data.key?(:summary)
      return content.split(site.config[:summary_separator], 2).first if site.config.key?(:summary_separator) && content.match?(site.config[:summary_separator])

      content.to_s.strip.lines.first.to_s.strip.html_safe
    end
  end
end