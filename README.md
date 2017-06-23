# Inverted Index Algorithm

Implementation of inverted index algorithm with vector space model for scoring for fast full-text searches.

An inverted index (also referred to as postings file or inverted file) is an index data structure storing a mapping from content, such as words or numbers, to its locations in a database file, or in a document or a set of documents (named in contrast to a Forward Index, which maps from documents to content). The purpose of an inverted index is to allow fast full text searches.

Vector space model is an algebraic model for representing text documents as vectors of identifiers, such as, for example, index terms. It is used in information filtering, information retrieval, indexing and relevancy rankings.


### References :
1. https://nlp.stanford.edu/IR-book/pdf/irbookonlinereading.pdf
2. https://nlp.stanford.edu/IR-book/html/htmledition/scoring-term-weighting-and-the-vector-space-model-1.html
3. https://en.wikipedia.org/wiki/Vector_space_model

### Example

```sh
$ irb
> require_relative 'query'
> ri = Query.new('/path/to/directory/to/index')
> ri.find('query terms as string')
1 : /path/to/001-something.cpp
2 : /path/to/007-else.py
3 : /path/to/008-impossible.js
4 : /path/to/002-however.rb
```
