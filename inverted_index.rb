class InvertedIndex

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
    file_list
    index_files
    calculate_weights
  end

  def file_list
    valid_file_paths = Dir.glob("#{path}/**/*.{#{FILE_EXTS.join(',')}}")
    index_map = valid_file_paths.each_with_index.map { |x, i| [i+1, x] }
    @files = Hash[index_map]
  end

  def index_files
    @files.each do |file_id, file_path|
      index_document(file_id, file_path)
    end
  end

  def index_document(file_id, file_path)
    @document[file_id] ||= { total: 0 }
    f = File.new(file_path)
    prev_fp = f.tell
    f.each_line do |line|
      words = tokenize_line(line)
      progressive_index(words, file_id, prev_fp)
      prev_fp = f.tell
    end
  end

  def tokenize_line(line)
    line.gsub(STOPPER, ' ').gsub(/(\s)+/i, ' ').split(' ').map(&:downcase)
  end

  def progressive_index(words, file_id, prev_fp)
    words.each do |word|
      update_document_index(file_id, word)
      update_term_index(file_id, prev_fp, word)
    end
  end

  def update_document_index(file_id, word)
    @document[file_id][word] ||= { count: 0 }
    @document[file_id][word][:count] += 1
    @document[file_id][:total] += 1
  end

  def update_term_index(file_id, prev_fp, word)
    unless @terms[word]
      @terms[word] = { 
        count: 1,
        occurences: { 
          file_id => [prev_fp]
        }
      }
      return
    end
    
    @terms[word][:count] += 1
    @terms[word][:occurences][file_id] ||= []
    @terms[word][:occurences][file_id] << prev_fp
  end

  def calculate_weights
    @terms.each { |word, postings| term_weight(word, postings) }
  end

  def term_weight(word, postings)
    postings[:occurences].each do |file_id, positions|

      df = positions.size
      idf = Math.log(@document.keys.size.to_f/df)
      tf = positions.size

      @document[file_id][word][:tf] = tf
      @document[file_id][word][:idf] = idf
      @document[file_id][word][:weight] = tf * idf
    end
  end

end
