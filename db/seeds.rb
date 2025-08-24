puts "Creating articles for performance testing..."

# Create 10,000 articles for testing (faster seeding)
Article.create!(
  Array.new(10_000) do |i|
    {
      title: "Article #{i + 1}: Sample Title for Performance Testing",
      content: "This is sample content for article #{i + 1}. " + "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 10,
      created_at: Time.current - rand(365).days,
      updated_at: Time.current
    }
  end
)

puts "Finished creating #{Article.count} articles"
