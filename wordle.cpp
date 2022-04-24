#include <iostream>
#include <vector>
#include <string>
#include <array>
#include <list>
#include <cassert>
#include <unordered_map>

const int WORDLE_LEN = 5;

/* Possible values the wordle scoring will return */
enum Result {
  UnInit  = 0,
  Correct = 1,
  Shifted = 2,
  Wrong   = 3
};

std::string str_result(Result const& r) {
  std::string ret;
  switch(r) {
  case UnInit:
    ret = "UnInit";
    break;
  case Correct:
    ret = "Correct";
    break;
  case Shifted:
    ret = "Shifted";
    break;
  case Wrong:
    ret = "Wrong";
    break;
  default:
    ret = "Invalid:" + std::to_string((int)r);
  }
  return ret;
}

/* A score has exactly as many results as characters in the words */
using Score = std::array<Result, WORDLE_LEN>;
const Score null_score = {};
const Score winner = Score{Correct,Correct,Correct,Correct,Correct};

/* A word always has 5 lower cased characters, but I don't think it is worth type-enforcing this */
using Word = std::string;

/* Any ForwardIterable container should work */
using WordList = std::list<Word>;

/* minimax tree node */
struct Node;
using NodeRef = std::shared_ptr<Node>;
using NodeList = std::list<NodeRef>;

struct Node {
  Word      word;
  Score     score;
  WordList  remaining;
  NodeList  children;
};


// Obtained from https://bert.org/assets/posts/wordle/words.json'
#include "wordlelist.cpp"

Score score_guess(Word guess, Word answer) {
  Score ret;
  for(int idx=0; idx<WORDLE_LEN; idx++) {
    if(guess[idx]==answer[idx]) {
      ret[idx] = Correct;
    } else if(answer.find(guess[idx]) != std::string::npos) {
      ret[idx] = Shifted;
    } else {
      ret[idx] = Wrong;
    }
  }
  return ret;
}



void build_decision_tree(Score current_score, WordList current_words) {
  if(current_score == null_score) {
    std::cout << "Score is default value" << std::endl;
  }
}

std::ostream& operator<<(std::ostream& os, Score const& score) {
  os << "[";
  os << str_result(score[0]);
  os << ", ";
  os << str_result(score[1]);
  os << ", ";
  os << str_result(score[2]);
  os << ", ";
  os << str_result(score[3]);
  os << ", ";
  os << str_result(score[4]);
  os << "]";
  return os;
}

int main() {
  std::cout << score_guess("cigar","later") << std::endl;


  Node root;
  root.remaining = word_list;

  return 0;
}
