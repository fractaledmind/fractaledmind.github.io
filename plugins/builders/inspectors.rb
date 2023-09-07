class Builders::Inspectors < SiteBuilder
  def build
    inspect_html do |document|
      document.css("main").css("h2[id],h3[id],h4[id],h5[id],h6[id]").each do |heading|
        anchor = %(
          <a href="##{heading[:id]}" class="anchor" aria-hidden="true">#</a>
        )
        heading << anchor
      end
    end
  end
end