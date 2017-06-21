class IndexFiles

  attr_accessor :path, :files, :terms, :document

  FILE_EXTS = ['cpp', 'rb', 'js', 'html', 'css', 'py', 'c']
  STOPPER = /[^0-9a-z _-]/i

  def initialize(dir_path = Dir.pwd)
    @path = dir_path
    @files = {}
    @terms = {}
    @document = {}
  end

  def start
    fileMap
    queryMap
    df_idf
  end

  def fileMap
    valid_file_paths = Dir.glob("#{path}/*.{#{FILE_EXTS.join(',')}}")
    index_map = valid_file_paths.each_with_index.map { |x, i| [i+1, x] }
    @files = Hash[index_map]
  end

  def queryMap
    @files.each do |file_id, file_path|
      tokenizeDocument(file_id, file_path)
    end
  end

  def tokenizeDocument(file_id, file_path)
    @document[file_id] ||= { total: 0 }
    f = File.new(file_path)
    prev_fp = f.tell
    f.each_line do |line|
      words = tokenizeLine(line)
      progressiveMap(words, file_id, prev_fp)
      prev_fp = f.tell
    end
  end

  def tokenizeLine(line)
    line.gsub(STOPPER, ' ').gsub(/(\s)+/i, ' ').split(' ')
  end

  def progressiveMap(words, file_id, prev_fp)
    words.each do |word|
      documentMap(file_id, word)
      termMap(file_id, prev_fp, word)
    end
  end

  def documentMap(file_id, word)
    @document[file_id][word] ||= { count: 0 }
    @document[file_id][word][:count] += 1
    @document[file_id][:total] += 1
  end

  def termMap(file_id, prev_fp, word)
    if @terms[word]
      @terms[word][:count] += 1
      @terms[word][:occurences][file_id] ||= []
      @terms[word][:occurences][file_id] << prev_fp
    else
      @terms[word] = { count: 1, occurences: { file_id => [prev_fp] } }
    end
  end

  def df_idf
    number_of_docs = @document.keys.size
    @terms.each do |word, details|
      files_having_term_count = details[:occurences].keys.count
      idf = Math.log(number_of_docs.to_f/files_having_term_count, 2)
      # p "idf: #{idf}, number_of_docs: #{number_of_docs}, files_having_term_count: #{files_having_term_count}"
      details[:occurences].each do |file_id, positions|
        df = positions.size
        @document[file_id][word][:df] = df
        @document[file_id][word][:idf] = idf
        @document[file_id][word][:weight] = df * idf
      end
    end
  end

end

hh = IndexFiles.new("/Users/sony/codes/others/useful-random-scripts/stl_learning")
hh.start