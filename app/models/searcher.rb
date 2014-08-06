class Searcher

  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    all_class_results = PgSearch.multisearch(query.search_terms) # => ActiveRecord::Relation
    {
      "Topic"          => all_class_results.where(searchable_type: "Topic"),
      "StillImage"     => all_class_results.where(searchable_type: "StillImage"),
      "AudioRecording" => all_class_results.where(searchable_type: "AudioRecording"),
      "Video"          => all_class_results.where(searchable_type: "Video"),
      "WebLink"        => all_class_results.where(searchable_type: "WebLink"),
      "Document"       => all_class_results.where(searchable_type: "Document"),
      "Comment"        => all_class_results.where(searchable_type: "Comment")
    }
  end

  def all
    all_results = PgSearch::Document.where('1=1') 
    {
      "Topic"          => all_results.where(searchable_type: "Topic"),
      "StillImage"     => all_results.where(searchable_type: "StillImage"),
      "AudioRecording" => all_results.where(searchable_type: "AudioRecording"),
      "Video"          => all_results.where(searchable_type: "Video"),
      "WebLink"        => all_results.where(searchable_type: "WebLink"),
      "Document"       => all_results.where(searchable_type: "Document"),
      "Comment"        => all_results.where(searchable_type: "Comment")
    }
  end

  def tagged
    {
      "Topic"          => Topic.tagged_with(query.tag),
      "StillImage"     => StillImage.tagged_with(query.tag),
      "AudioRecording" => AudioRecording.tagged_with(query.tag),
      "Video"          => Video.tagged_with(query.tag),
      "WebLink"        => WebLink.tagged_with(query.tag),
      "Document"       => Document.tagged_with(query.tag),
      "Comment"        => Comment.tagged_with(query.tag)
    }
  end

  private

  attr_reader :query

end
