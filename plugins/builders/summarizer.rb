class Builders::Summarizer < SiteBuilder
  def build
    define_resource_method :summary_extension_output do
      summary = if data.key?(:summary)
        data[:summary]
      elsif site.config.key?(:summary_separator) && content.match?(site.config[:summary_separator])
        content.split(site.config[:summary_separator], 2).first
      else
        content.to_s.strip.lines.first.to_s.strip.html_safe
      end
      
      summary.strip!
      
      if !summary.start_with?('<p>') && !summary.end_with?('</p>')
        "<p>#{summary}</p>"
      elsif summary.start_with?('<p>') && !summary.end_with?('</p>')
        "#{summary}</p>"
      elsif !summary.start_with?('<p>') && summary.end_with?('</p>')
        "<p>#{summary}"
      elsif summary.start_with?('<p>') && summary.end_with?('</p>')
        summary
      end
    end
  end
end