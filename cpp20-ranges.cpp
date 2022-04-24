#include <iostream>
#include <ranges>

int main() {

  using namespace std::views;

  /* grab odd squares from first 20 integers */
  auto seq =
      iota(0)
    | take(20)
    | transform([](auto i){return i*i;})
    | filter([](auto i){return i%2==1;});

  /* Print range */
  for(auto s : seq)
    std::cout << s << " ";
  std::cout << "\n";
  /* => 1 9 25 49 81 121 169 225 289 361  */

  return 0;
}
