require 'inverted_index'

class Query

  attr_accessor :path, :query, :q_tokens, :q_vector, :qtf, :reverse_index, :matches, :file_weights

  MAX_RESULTS = 5

  def initialize(dir_path)
    @path = dir_path
    @reverse_index = ::InvertedIndex.new(dir_path)
    @reverse_index.start
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
  end

  def search_index
    find_matches
    if @matches.empty?
      puts "No results"
      return
    end
    query_vector_weight
    cosine_similarity(matches)
  end

  def tokenize_query
    @q_tokens = @query.gsub(InvertedIndex::STOPPER, ' ').gsub(/(\s)+/i, ' ').split(' ').map(&:downcase)
    @qtf = @q_tokens.group_by { |w| w }.map { |w, ws| [w, ws.length] }.to_h
  end

  def query_vector_weight
    number_of_docs = @reverse_index.document.keys.size + 1
    @qtf.each { |word, freq| token_weight(word, freq, number_of_docs) }
  end

  def token_weight(word, freq, number_of_docs)
    @q_vector[word] ||= {}
    @q_vector[word][:df] = freq
    
    files_having_term_count = @reverse_index.terms[word][:occurences].keys.count + 1
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
      cumulative_weights = 0.0
      msqrt_doc = 0.0
      msqrt_query = 0.0
      @qtf.each do |word, freq|
        wtd = (@reverse_index.document[file_id][word] || {})[:weight]
        wtq = @q_vector[word][:weight]

        cumulative_weights += wtd*wtq
        msqrt_doc += (wtd*wtd)
        msqrt_query += (wtq*wtq)
      end
      msqrt = (Math.sqrt(msqrt_doc) * Math.sqrt(msqrt_query))
      p "msqrt : #{msqrt}, cw : #{cumulative_weights}"
      dot_product = cumulative_weights.to_f/msqrt
      p "dot_product : #{dot_product}"
      @file_weights[file_id] = dot_product
    end
  end

end

kk = Query.new('/Users/sony/codes/others/useful-random-scripts')
kk.find('PaperFold')