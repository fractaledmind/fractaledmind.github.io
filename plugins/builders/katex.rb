require 'nokogiri'
require 'open3'

class Builders::Katex < SiteBuilder
  SELECTOR = '[data-katex]'.freeze
  
  def build
    inspect_html do |document|
      document.query_selector_all(SELECTOR).each do |element|
        result, _stderr_str, _status = Open3.capture3("npx katex", stdin_data: element.text)
p '*' * 100
p ['locale', Encoding.locale_charmap]
p ['filesystem', Encoding.find('filesystem')]
p ['external', Encoding.default_external]
p ['internal', Encoding.default_internal]
p ['result', result.encoding]
        element.replace(result.encode('UTF-8', 'US-ASCII').strip)
      end
    end
  end
end
