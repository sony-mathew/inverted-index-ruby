require_relative 'inverted_index'

class Query

  attr_accessor :path, :query, :q_tokens, :q_vector, :qtf, :index, :matches, :file_weights

  MAX_RESULTS = 5

  def initialize(dir_path)
    @path = dir_path
    @index = InvertedIndex.new(dir_path)
    @index.start
  end

  def find q
    init_query(q)
    search_index
  end

  def init_query(q)
    @q_vector = {}
    @matches = {}
    @file_weights = {}
    @query = q
    tokenize_query
    query_vector
  end

  def search_index
    find_matches
    if @matches.empty?
      puts "No results"
      return
    end
    cosine_similarity(matches)
    results
  end

  def tokenize_query
    @q_tokens = @index.tokenize(@query)
    # finding query token frequency, qtf
    @qtf = @q_tokens.group_by { |w| w }.map { |w, ws| [w, ws.length] }.to_h
  end

  def query_vector
    msq = @qtf.map { |w, f| f*f }.reduce(:+)
    msqrt = Math.sqrt(msq)
    @qtf.each { |w, f| @q_vector[w] = f.to_f/msqrt }
  end

  def find_matches
    @qtf.each { |w, f| @matches[w] = @index.terms[w] if @index.terms[w] }
  end

  def cosine_similarity(matches)
    matching_files = @matches.map { |w, pos| pos[:occurences].keys }.flatten.uniq

    matching_files.each do |file_id|
      cumulative_wt = 0.0
      @q_vector.each do |w, wtq|
        wtd = (@index.document[file_id][w] || {})[:wt] || 0
        cumulative_wt += wtd*wtq
      end
      @file_weights[file_id] = cumulative_wt
    end
    @file_weights = @file_weights.sort_by { |f, w| w }.reverse
  end

  def results
    @file_weights.first(MAX_RESULTS).each_with_index do |f, i|
      puts "#{i + 1} : #{@index.files[f[0]]}"
    end
  end

end
