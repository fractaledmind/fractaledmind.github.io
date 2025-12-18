class Builders::Torchlight < SiteBuilder
  def build
    hook :site, :post_write, priority: :high do
      # next unless Bridgetown.env.production?

      system "yarn torchlight"
      add_1p_ignore_to_pre_tags
    end
  end

  def add_1p_ignore_to_pre_tags
    Dir.glob("output/**/*.html").each do |file|
      content = File.read(file)
      # Add data-1p-ignore to pre tags that don't already have it
      modified = content.gsub(/<pre(?![^>]*data-1p-ignore)/) do |match|
        "#{match} data-1p-ignore"
      end
      File.write(file, modified) if content != modified
    end
  end
end