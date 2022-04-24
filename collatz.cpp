#include <cstdio>
#include <cstring>
#include <string>
#include <deque>
#include <unordered_set>
#include <algorithm>
#include <iostream>
#include <mutex>

#include <boost/asio.hpp>
#include <boost/asio/thread_pool.hpp>
#include <boost/multiprecision/tommath.hpp>

using ZInt = boost::multiprecision::tom_int;
using ZList = std::deque<ZInt>;
using ZLoop = std::set<ZInt>;
using ZRet = std::tuple<bool, ZList, ZLoop>;
//using ZLoopList = std::unordered_set<ZList>;

// Run the collatz algorithm on the given initial value, returning a tuple of (did_halt?, complete output list, looping part of the list)
ZRet collatz(const ZInt multiplier, const ZInt divisor, const ZInt maxiter, const ZInt initial) {
  ZList list;
  ZLoop loop_detect;

  list.push_back(initial);
  loop_detect.insert(initial);

  ZInt current = initial;

  for(ZInt i = 0; i < maxiter; i++) {
    // perform collatz transform
    if(current % divisor != 0) {
      current = current*multiplier + 1;
    } else {
      current = current / divisor;
    }
    // loop detect
    if(loop_detect.find(current)!=loop_detect.end()) {
      ZLoop loop;
      // locate loop start
      auto iter = std::find_if(list.crbegin(), list.crend(), [&current](auto i){ return i == current; });
      // copy loop
      loop.insert(*iter);
      while (iter != list.crbegin()) {
        loop.insert(*--iter);
      }
      return ZRet(true,std::move(list),std::move(loop));
    }
    // save and continue
    loop_detect.insert(current);
    list.push_back(current);
  }
    return ZRet(false,std::move(list),ZLoop());
}

namespace std {
  std::string to_string(const ZInt &z) {
    return z.str();
  }
  /* wth is there no to_string for string?! */
  std::string to_string(const std::string &z) {
    return z;
  }
}

template<class Container>
std::string join(const Container &c, const std::string &delim) {

  std::string res;

  if(c.size() == 0)
    return res;

  auto iter = c.cbegin();
  res += std::to_string(*iter);

  if(c.size() == 1)
    return res;

  while(++iter != c.cend()) {
    res += delim;
    res += std::to_string(*iter);
  }

  return res;
}

void characterize(const int m_range_min, const int m_range_max, const int d_range_min, const int d_range_max, const int maxiter, const int maxinput) {
  boost::asio::thread_pool pool(64);
  std::list<std::string> results;
  std::mutex results_mutex;

  std::printf("{\n"
              "  \"maxiter\":%i,\n"
              "  \"maxinput\":%i,\n"
              "  \"m_max\":%i,\n"
              "  \"d_max\":%i,\n"
              "  \"results\":[\n",maxiter,maxinput,m_range_max,d_range_max);

  for(int m = m_range_min; m < m_range_max; m++) {
    for(int d = d_range_min; d < d_range_max; d++) {
      boost::asio::post(pool, [&results,&results_mutex,m,d,maxiter,maxinput]() {
        bool all_halt = true;
        int nloops = 0;
        std::set<ZLoop> loops;

        for(int i=1; i<maxinput; i++) {
          auto ret = collatz(m,d,maxiter,i);
          if( !std::get<0>(ret) ) {
            all_halt = false;
            //  break;
          } else {
            nloops++;
            loops.insert(std::get<2>(ret));
          }
        }
        std::string res;
        res += "    {\n";
        res += "      \"m\":"; res += std::to_string(m); res += ",\n";
        res += "      \"d\":"; res += std::to_string(d); res += ",\n";
        res += "      \"cases_that_looped\":"; res += std::to_string(nloops); res += ",\n";
        res += "      \"unique_loops\":"; res += std::to_string(loops.size()); res += ",\n";
        res += "      \"loops\":[\n";

        if(loops.size() > 0) {
          std::list<std::string> loops_inner_str;

          std::transform(loops.cbegin(), loops.cend(), std::back_inserter(loops_inner_str), [](const auto& loop){
            std::string loopstr = join(loop, ", ");
            return std::string("        [") + loopstr + "]";
          });
          res += join(loops_inner_str,",\n");
          res += "\n";
        }

        res += "      ]\n";
        res += "    }";
        std::lock_guard<std::mutex> guard(results_mutex);
        results.push_back(res);
      });
    }
  }
  pool.join();
  //std::copy(results.begin(), results.end(), std::ostream_iterator<std::string>(std::cout, ",\n"));
  //std::cout.flush();
  auto str = join(results,",\n");
  std::printf("%s",str.c_str());
  std::printf("\n");
  std::printf("  ]\n");
  std::printf("}\n");
}

void print_collatz(int m, int d, int max, int i) {
  ZRet ret = collatz(m,d,max,i);

  if(std::get<0>(ret)) {
    std::cout << "all: " << join(std::get<1>(ret),", ") << std::endl;
    std::cout << "loop: " << join(std::get<2>(ret),", ") << std::endl;
  } else {
    std::cout << "end: " << std::to_string(*std::get<1>(ret).crbegin()) << std::endl;
  }

}

int main(int argc, char *argv[]) {

  if(argc == 5) {
    print_collatz(std::stoi(argv[1],nullptr),
                  std::stoi(argv[2],nullptr),
                  std::stoi(argv[3],nullptr),
                  std::stoi(argv[4],nullptr));
  } else {

    characterize(2,200,2,200,1000,1000);
  }
  return 0;
}


// for(ZInt x=1; x<10000; x++) {
//   auto ret = collatz(5,3,20,x);
//   if(std::get<0>(ret)) {
//     std::printf("X=%s:\n    ", x.str().c_str());
//     if(std::get<0>(ret)) {
//     } else {
//       std::printf("nohalt: ");
//     }
//     for (const auto &i : std::get<1>(ret)) {
//       std::printf("%s, ", i.str().c_str());
//     }
//     std::printf("\n\n");
//   }
//  }

