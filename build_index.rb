# Ref :
# 1. https://nlp.stanford.edu/IR-book/html/htmledition/contents-1.html
# 2. https://en.wikipedia.org/wiki/Vector_space_model

class BuildIndex

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
    weight_vector
  end

  def file_list
    valid_file_paths = Dir.glob("#{path}/*.{#{FILE_EXTS.join(',')}}")
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

  def weight_vector
    number_of_docs = @document.keys.size
    @terms.each do |word, details|
      files_having_term_count = details[:occurences].keys.count
      idf = Math.log(number_of_docs.to_f/files_having_term_count, 2)
      word_rankings(word, word_map, idf)
    end
  end

  def word_rankings(word, word_map, idf)
    word_map[:occurences].each do |file_id, positions|
      df = positions.size
      @document[file_id][word][:df] = df
      @document[file_id][word][:idf] = idf
      @document[file_id][word][:weight] = df * idf
    end
  end

end
