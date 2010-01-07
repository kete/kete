module CommentsHelper
  # Splits each paragraph, then splits each line break.
  # then sends that to clean_and_wrap. The result is then
  # joined back together with line breaks where needed
  def quoted_description_of(comment)
    description = comment.description
    paragraphs = description.split('</p>')
    paragraphs.collect! do |paragraph|
      lines = paragraph.split(/<br\s?\/?>/)
      lines.collect! do |line|
        clean_and_wrap(line)
      end.join('<br />')
    end.join('<br />&gt;<br />')
  end

  # Takes a line, strips tags, strips whitespace, wraps the lines
  # Collects each wrapped line and appends a "> " to the front of it
  # Then joins each wrapped lines together with a line break
  def clean_and_wrap(line)
    clean_line = line.strip_tags.strip
    wrapped_lines = word_wrap(clean_line)
    wrapped_lines_array = wrapped_lines.split("\n")
    wrapped_lines_array.collect! { |wrapped_line| "&gt; #{wrapped_line}" }
    wrapped_lines_array.join('<br />')
  end
end
