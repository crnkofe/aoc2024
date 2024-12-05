import gleam/order
import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

pub type Day5Input {
  Day5Input(page_ordering_rules: dict.Dict(String, List(String)), updates: List(List(String)))
}

fn read_file_day5(filename) -> Day5Input {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  let page_ordering_rules = lines |> list.take_while(fn (l) {
    string.length(string.trim_end(l)) > 0
  }) |> list.map(fn(l) {
    l |> string.trim_end |> string.split("|")
  }) |> list.group(fn (l) {
    util.assert_nth(l, 0)
  }) |> dict.map_values(fn(_k, v) {
    v |> list.map(fn (p) {
      util.assert_nth(p, 1)
    })
  })

  let updates = lines |> list.drop_while(fn (l) {
    string.length(string.trim_end(l)) > 0
  }) |> list.map(fn(update) {
    string.trim_end(update) |> string.split(",")
  })

  Day5Input(page_ordering_rules, updates)
}

fn process_config(config: Day5Input) -> #(Int, Int) {
  let processed_updates: List(#(Bool, List(String))) = list.map(config.updates, fn(update) {
    let comb_pairs = list.combination_pairs(update)
    let valid_pairs = comb_pairs |> list.filter(fn(p) {
      // Check if any mapping p0, p1 has a rule p.1|p.0
      // That means the rule is invalid
      case dict.get(config.page_ordering_rules, p.0) {
        Ok(lst) -> list.contains(lst, p.1)
        Error(_) -> False
      }
    })
    #(list.length(update) > 1 && {list.length(comb_pairs) == list.length(valid_pairs)}, update)
  })

  let valid_sum = processed_updates
    |> list.filter(fn(x) { x.0 })
    |> list.map(fn(x) { x.1 })
    |> list.map(fn(valid_update) {
      let mid_index = list.length(valid_update) / 2
      let assert Ok(num) = int.parse(util.assert_nth(valid_update, mid_index))
      num
    })
    |> list.fold(0, int.add)

  let invalid_updates = processed_updates
  |> list.filter(fn(x) { !x.0})
  |> list.map(fn(x) { x.1 })

  let corrected_sum = invalid_updates
    |> list.filter(fn(x) {list.length(x) > 1})
    |> list.map(fn(invalid_update) {
        list.sort(invalid_update, fn(x: String, y: String) -> order.Order {
          case x == y {
            True -> order.Eq
            False -> {
              case dict.get(config.page_ordering_rules, x) {
                Ok(lst) -> {
                  case list.contains(lst, y) {
                    True -> order.Lt
                    False -> order.Gt
                  }
                }
                Error(_) -> order.Gt
              }
            }
          }}
      )
      })
    |> list.map(fn(now_valid_update) {
      let mid_index = list.length(now_valid_update) / 2
      let assert Ok(num) = int.parse(util.assert_nth(now_valid_update, mid_index))
      num
    })
    |> list.fold(0, int.add)
  #(valid_sum, corrected_sum)
}

pub fn main() {
  io.print("Day 5 (test): ")
  let sums_test = "./test5.txt" |> read_file_day5 |> process_config
  sums_test.0 |> int.to_string |> io.println
  io.print("Day 5 p2 (test): ")
  sums_test.1 |> int.to_string |> io.println

  let sums_input = "./day5.txt" |> read_file_day5 |> process_config
  io.print("Day 5 (input): ")
  sums_input.0 |> int.to_string |> io.println
  io.print("Day 5 p2 (input): ")
  sums_input.1 |> int.to_string |> io.println
}
