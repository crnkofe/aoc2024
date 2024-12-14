import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import file_streams/file_stream as fs

fn read_file_day11(filename) -> List(Int) {
  let assert Ok(f) = fs.open_read(filename)
  let line = util.read_loop(f, []) |> list.map(fn (line) {
    line |> string.trim_end |> string.split(" ") |> list.map(fn(w) {
      let assert Ok(n) = int.parse(w)
      n
    })
  }) |> list.flatten
  line
}

fn is_even(n: Int) {
  let s = int.to_string(n)
  int.is_even(string.length(s))
}

fn split(n: Int) -> #(Int, Int) {
  let s = int.to_string(n)
  let slen = string.length(s)
  let s1 = string.slice(s, 0, slen / 2)
  let s2 = string.slice(s, slen / 2, slen / 2)
  let assert Ok(p1) = int.parse(s1)
  let assert Ok(p2) = int.parse(s2)
  #(p1, p2)
}

fn count_stones(n: Int, depth: Int, cache: dict.Dict(util.Point, Int)) -> Int {
  case depth {
    0 -> {
      1
    }
    _ -> {
      case dict.get(cache, #(depth, n)) {
        Ok(stone_count) -> stone_count
        _ -> {
          case n == 0 {
            True -> {
              count_stones(1, depth-1, cache)
            }
            _ -> {
              case is_even(n) {
                True -> {
                  let #(p1, p2) = split(n)
                  count_stones(p1, depth-1, cache) + count_stones(p2, depth-1, cache)
                }
                False -> count_stones(n * 2024, depth-1, cache)
              }
            }
          }
        }
      }
    }
  }
}

pub fn main() {
  // prepopulate cache
  let interesting_nums = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 2024]
  let cache = interesting_nums |> list.map(fn (n) {
    let depths = list.range(1, 40)
    list.map(depths, fn (d) {
      #(d, n)
    })
  }) |> list.flatten |> list.fold(dict.from_list([]), fn (cache: dict.Dict(util.Point, Int), p: util.Point) {
    dict.insert(cache, p, count_stones(p.1, p.0, cache))
  })

  util.print_num("Day 11 (test)", "./test11.txt"
  |> read_file_day11 |> list.fold(0, fn(res, n) {
    res + count_stones(n, 25, cache) })
  )

  util.print_num("Day 11 (input)", "./day11.txt"
  |> read_file_day11 |> list.fold(0, fn(res, n) {
    res + count_stones(n, 25, cache) })
  )

  util.print_num("Day 11 p2 (input)", "./day11.txt"
  |> read_file_day11 |> list.fold(0, fn(res, n) {
    res + count_stones(n, 75, cache) })
  )
}
