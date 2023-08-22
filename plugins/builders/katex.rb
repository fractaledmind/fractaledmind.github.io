require 'nokogiri'
require 'open3'

class Builders::Katex < SiteBuilder
  SELECTOR = '[data-katex]'.freeze
  
  def build
    inspect_html do |document|
      document.query_selector_all(SELECTOR).each do |element|
        result, _stderr_str, _status = Open3.capture3("npx katex", stdin_data: element.text)
        element.replace(result.strip)
      end
    end
  end
end
