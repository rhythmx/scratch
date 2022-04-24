#!/bin/env ruby

require 'irb'

# Wordle is a simple game available here:
# https://www.powerlanguage.co.uk/wordle/. You guess a word and using
# information about which letters are included and perhaps in the correct
# position or not, make subsequent guesses as to the correct answer.

# The "dictionary" of words that Wordle uses for the puzzle is available as a
# JSON file for download. Let's grab that and save it as the Array "word_list".

require 'uri'
require 'net/http'
require 'json'

# also cache to filesystem to be nice
if !File.exists?(".wordlelist")
  uri = URI('https://bert.org/assets/posts/wordle/words.json')
  res = Net::HTTP.get_response(uri)
  raise "fetch error" if !res.is_a?(Net::HTTPSuccess)
  File.open(".wordlelist","wb"){ |f| f.write(res.body) }
  word_list = JSON.parse(res.body)["solutions"]
else
  word_list = JSON.parse(File.read(".wordlelist"))["solutions"]
end



# Using the new `char_freq_map` we can calculate a "score" for every possible
# word. Note that we do not want to count duplicate letters into the score,
# because that decreases the information obtained by making a guess.
def word_score2(word,char_freq_map)
  word.each_char.uniq.inject(0) do |score, ch|
    score += char_freq_map[ch]
  end
end

# Lets figure out the score for every word
def calculate_word_scores2(word_list)
  # do some character freq analysis on word_list, create {'a' => num_As, 'b' => numBs, ...}
  char_freq_map = word_list.inject(Hash.new(0)) do |cfmap, word|
    word.each_char do |ch|
      cfmap[ch] += 1
    end
    cfmap
  end
  word_list.inject({}) do |ws,word|
    ws[word] = word_score2(word,char_freq_map)
    ws
  end
end


def word_score(word,char_idx_freq_map)
  (0..4).inject(0) do |sum,idx|
    sum += char_idx_freq_map[idx][word[idx]]
    sum
  end
end

# Lets figure out the score for every word
def calculate_word_scores(word_list)
  # do some character freq analysis on word_list, create {'a' => num_As, 'b' => numBs, ...}
  char_idx_freq_map = (0..4).map do |idx| 
    word_list.inject(Hash.new(0)) do |cfmap, word|
      cfmap[word[idx]] += 1
      cfmap
    end
  end
  word_list.inject({}) do |ws,word|
    ws[word] = word_score(word,char_idx_freq_map)
    ws
  end
end

# Using scoring, we can sort all words by their score (decending)
def sort_words_by_score(words)
  word_scores = calculate_word_scores(words)
  word_scores2 = calculate_word_scores2(words)
  words.sort do |a,b|
    (word_scores[b])*(word_scores2[b]) <=> (word_scores[a])*(word_scores2[a])
  end
end

# Now we know the best starting words, "later,alter,alert" all tie for highest score

# Knowing the scores of all possible starting points, we can begin to "solve" 
# the puzzle. That is, for every possible word, we can start at the best word
# and calculate all the possible hints, then select all the remaining 
# possibilities and repeat recursively. Eventually you end up with a tree
# representing the best possible move in any given situation.

# First, we implement the wordle scoring function
def score_guess(guess, answer)
  raise "invalid guess length" if guess.length != answer.length
  (0...guess.length).map do |idx|
    if guess[idx] == answer[idx]
      :correct
    elsif answer.include?(guess[idx])
      :shifted
    else
      :wrong
    end
  end
end

# binding.irb
guess = "alter"
answer = "siege"

score = score_guess(guess,answer)

def remaining_words(guess, score, wordlist)
  wordlist.find_all do |word|
    idx = 0
    res = true
    while idx < guess.length
      case score[idx]
      when :correct
        if word[idx] != guess[idx]
          res = false
          break
        end
      when :shifted
        if !word.include?(guess[idx]) or word[idx] == guess[idx]
          res = false
          break
        end
      when :wrong
        if word.include?(guess[idx])
          res = false
          break
        end
      end
      idx+=1
    end
    res
  end
end

def play_game(starting_word, answer, word_list)
  game_over = false
  round = 1
  word = starting_word
  remaining_words = word_list.clone
  while !game_over
    score = score_guess(word, answer)
    puts "#{word} => #{score.inspect}"
    if score == [:correct]*5
      game_over = true
    else
      remaining_words = sort_words_by_score(remaining_words(word, score, remaining_words))
      word = remaining_words.first
      round += 1
    end
  end
  round
end

def characterize_starting_word(starting_word, word_list)
   all_games = all_games_for_word = word_list.inject({}) do |res,word|
     res[word] = play_game(starting_word,word,word_list)
     res
   end
   distribution = all_games.inject(Hash.new(0)) {|dist,game| dist[game[1]] += 1; dist}
   binding.irb
   distribution.keys.max
end

# ch = characterize_starting_word(sort_words_by_score(word_list).first, word_list)

# def characterize_all_words(word_list)
#   word_list.inject({}) do |res,word|
#     res[word] = characterize_starting_word(word, word_list)
#     res
#   end
# end

# all_words = characterize_all_words(word_list)

def ask_score()
  begin
    print "What was the resulting score: "
    eval(readline)
  rescue => ex
    puts "That is not a valid score, please try again..."
    retry
  end
end

def play_game_interactive(word_list)
  game_over = false
  round = 1
  word = sort_words_by_score(word_list).first
  puts "Start with word '#{word}'"
  remaining_words = word_list.clone
  while !game_over
    score = ask_score()
    puts "#{word} => #{score.inspect}"
    if score == [:correct]*5
      game_over = true
    else
      remaining_words = sort_words_by_score(remaining_words(word, score, remaining_words))
      word = remaining_words.first
      puts "now try word: '#{word}'"
      round += 1
    end
  end
  round
end


binding.irb
