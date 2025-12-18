class Builders::Filters < SiteBuilder
  def build
    liquid_filter "plain_text" do |input|
      # Decode all HTML entities, then remove any characters that would be
      # re-escaped in HTML output (angle brackets, ampersands, quotes, slashes)
      CGI.unescapeHTML(input.to_s).gsub(%r{[<>&"'/]}, "")
    end
  end
end
