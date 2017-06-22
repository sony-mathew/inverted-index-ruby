require 'build_index.rb'

class QueryIndex

  attr_accessor :path, :query, :q_tokens, :q_vector, :qtf, :reverse_index, :matches, :file_weights

  MAX_RESULTS = 5

  def intialize(dir_path)
    @path = dir_path
    @reverse_index = BuildIndex.new(dir_path)
    @reverse_index.start
  end

  def find q
    init_query(q)
    search_index
  end

  def init_query(q)
    @query_vector = {}
    @matches = {}
    @file_weights = {}
    @query = q
    tokenize_query
    query_vector_weight
  end

  def search_index
    find_matches
    cosine_similarity(matches)
  end

  def tokenize_query
    @q_tokens = @query.gsub(BuildIndex::STOPPER, ' ').gsub(/(\s)+/i, ' ').split(' ').map(&:downcase)
    @qtf = @q_tokens.group_by { |w| w }.map { |w, ws| [w, ws.length] }.to_h
  end

  def query_vector_weight
    number_of_docs = @reverse_index.document.keys.size + 1
    @qtf.each { |word, freq| weight_of_term(word, freq, number_of_docs) }
  end

  def token_weight(word, freq, number_of_docs)
    @q_vector[word] ||= {}
    @q_vector[word][:df] = freq
    
    files_having_term_count = @reverse_index[word][:occurences].keys.count + 1
    idf = Math.log(number_of_docs.to_f/files_having_term_count, 2)

    @q_vector[word][:idf] = idf
    @q_vector[word][:weight] = freq * idf
  end

  def find_matches
    @q_tokens.each do |word|
      @matches[word] = @reverse_index.terms[word] if @reverse_index.terms[word]
    end
  end

  def cosine_similarity(matches)
    matching_files = @matches.map { |word, details| details[:occurences].keys }.flatten.uniq
    matching_files.each do |file_id|
      cumulative_weights = 0
      msqrt_doc = 0
      msqrt_query = 0
      @qtf.each do |word, freq|
        wtd = (@reverse_index.document[file_id][word] || {})[:weight]
        wtq = @q_vector[word][:weight]

        cumulative_weights += wtd*wtq
        msqrt_doc += (wtd*wtd)
        msqrt_query += (wtq*wtq)
      end
      msqrt_doc = Math.sqrt(msqrt_doc)
      msqrt_query = Math.sqrt(msqrt_query)
      dot_product = cumulative_weights/(msqrt_doc*msqrt_query)
      @file_weights[file_id] = dot_product
    end
  end

end
