# best 1-word is s
# best 2-word is es
# best 3-word is see
# best 4-word is sees
# best 5-word is sises
# best 6-word is assess
# best 7-word is sissies
# best 8-word is assesses
# best 9-word is senseless

require 'pp'
require 'set'

words = []
charfreqs = Hash.new(0)
File.open("/usr/share/dict/usa").each_line do |line|
  word = line.strip
  words << word
  line.strip.each_char{ |c| charfreqs[c] += 1 }
end
norep_words = words.find_all {|w| w.each_char.sort.uniq.size == w.size }

scores = norep_words.inject({}) do |s,w|
  score = w.each_char.inject(0){ |sum,c| sum += charfreqs[c] }
  if !s[w.size]
    s[w.size] = [score, w]
  else
    s[w.size] = [score, w] if s[w.size][0] < score
  end
  s
end

(1..9).each do |cnt| 
  puts "best #{cnt}-word is #{scores[cnt][1]}"
end


sixletters = norep_words.find_all {|w| w.size == 6}
sixletters_score = sixletters.inject({}) do |h,w|
  score = w.each_char.inject(0){ |sum,c| sum += charfreqs[c] }
  h[score] ||= Set.new
  h[score].add(w)
  h
end
keys = sixletters_score.keys.sort.reverse

pp sixletters_score[keys.first]
pp sixletters_score[keys[1]]
pp sixletters_score[keys[2]]
