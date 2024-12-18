import gleam/result.{unwrap}
import gleamy/map
import gleam/set.{type Set}
import gleam/float
import gleam/io
import gleam/int
import gleam/dict.{get,insert,type Dict}
import gleam/string
import util
import gleam/list
import file_streams/file_stream as fs
import gleamy/priority_queue as pq
import gleam/order

type Map = Dict(util.Point, String)

fn traverse(n: util.Point, prev: Dict(util.Point, util.Point), dist: Dict(util.Point, Int)) {
  case dist |> get(n) {
    Ok(0) -> [n]
    _ -> {
      case prev |> get(n) {
        Ok(an) -> {
          [n, ..traverse(an, prev, dist)]
        }
        _ -> []
      }
    }
  }
}

fn manhattan(p1: util.Point, p2: util.Point) {
  int.absolute_value(p2.1 - p1.1) + int.absolute_value(p2.0 - p1.0)
}

pub fn point_in_map(p: util.Point, map_size: Int) -> Bool {
  p.0 >= 0 && p.0 < map_size && p.1 >= 0 && p.1 < map_size
}

pub fn is_empty_space(p: util.Point, map: Map, size) {
  let count_empty_space = list.range(-1, 1) |> list.map(fn (y) {
    list.range(-1, 1) |> list.map(fn (x) {
      case map |> get(util.point_add(p, #(x, y))) {
        Ok("#") -> False
        _ -> point_in_map(util.point_add(p, #(x, y)), size)
      }
    })
  }) |> list.flatten |> list.filter(fn (x) { x }) |> list.length
  count_empty_space >= 9
}

fn print_map(map, at, size) {
  let is = list.range(0, size-1)
  let map_with_at = map |> insert(at, "@")
  is |> list.map(fn (y) {
    is |> list.fold("", fn(acc, x) {
      acc <> {map_with_at |> get(#(x, y)) |> unwrap(".")}
    }) |> io.println
  })
}

fn dijkstra(q: pq.Queue(util.Point), dist: Dict(util.Point, Int), prev: Dict(util.Point, util.Point), f_score: Dict(util.Point, Int), map: Map, map_size: Int, visited: set.Set(util.Point), e: util.Point) -> Int {
  case pq.pop(q) {
    Ok(#(p, rest)) -> {
      case p == e {
        True -> {
           // print_map(map, p, map_size)
           let t = traverse(p, prev, dist)
           t |> list.length
        }
        False -> {
          let q_dist = dist |> get(p) |> unwrap(util.max_int)
          // for each unvisited neighbour
          let ns = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
          |> list.map(fn (dir) { util.point_add(p, dir)})
          |> list.filter(fn (np) {
            point_in_map(np, map_size) &&
            !set.contains(visited, np) &&
            case map |> get(np) {
              Ok("#") -> False
              _ -> True
            }
          })
          let #(new_dist, new_prev, new_f_score) = ns
          |> list.fold(#(dist, prev, f_score), fn (acc, v) {
            let #(cur_dist, cur_prev, cur_f_score) = acc
            let alt = q_dist + 1
            let v_dist = dist |> get(v) |> unwrap(util.max_int)
            case alt < v_dist {
              True -> #(
                cur_dist |> insert(v, alt),
                cur_prev |> insert(v, p),
                cur_f_score |> insert(v, alt + manhattan(v, e))
              )
              False -> acc
            }
          })

          let new_q = ns |> list.fold(rest, fn(acc, n) {
            pq.push(acc, n)
          }) |> pq.reorder(fn(a, b) {
            int.compare(
              f_score |> get(a) |> unwrap(util.max_int),
              f_score |> get(b) |> unwrap(util.max_int)
            )
          })

          let new_visited = ns |> list.fold(visited, set.insert)
          dijkstra(new_q, new_dist, new_prev, new_f_score, map, map_size, new_visited, e)
        }
      }
    }
    _ -> {
      util.max_int
    }
  }
}

fn read_file_day18(filename, count) -> Map {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, [])
  |> list.take(count)
  |> list.map(fn (line) {
    let point = line |> string.trim_end |> string.split(",") |> list.map(int.parse) |> list.map(fn (ri) { ri |> unwrap(0) })
    case point {
      [a, b] -> #(#(a, b), "#")
      _ -> #(#(-1, -1), "?")
    }

  }) |> dict.from_list
}

fn read_file_all_day18(filename) -> List(#(util.Point, String)) {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, [])
  |> list.map(fn (line) {
    let point = line |> string.trim_end |> string.split(",") |> list.map(int.parse) |> list.map(fn (ri) { ri |> unwrap(0)})
    case point {
      [a, b] -> #(#(a, b), "#")
      _ -> #(#(-1, -1), "?")
    }
  })
}

fn find_unreachable(corrupted_blocks: List(#(util.Point, String)), map_size: Int, limit: Int) {
  let map = dict.from_list(corrupted_blocks |> list.take(limit))

  let path_len = dijkstra(pq.from_list([#(0, 0)], fn(_a, _b) { order.Eq }), dict.from_list([#(#(0, 0), 0)]), dict.from_list([]), dict.from_list([]), map, map_size, set.from_list([]), #(map_size-1, map_size-1))
  case path_len == util.max_int {
    True -> {util.assert_nth(corrupted_blocks, limit-1)}.0
    False -> find_unreachable(corrupted_blocks, map_size, limit+1)
  }
}

pub fn main() {
  let map_test = "test18.txt" |> read_file_day18(12)
  let path_len_test = dijkstra(pq.from_list([#(0, 0)], fn(_a, _b) { order.Eq }), dict.from_list([#(#(0, 0), 0)]), dict.from_list([]), dict.from_list([]), map_test, 7, set.from_list([]), #(6, 6))
  util.print_num("Day 18 (test)", path_len_test - 1)

  let corrupted_blocks_test = "test18.txt" |> read_file_all_day18
  let corr_test_p = find_unreachable(corrupted_blocks_test, 7, 1)
  io.print("Day 18 p2 (test): ")
  io.println(int.to_string(corr_test_p.0) <> "," <> int.to_string(corr_test_p.1))

  let map = "day18.txt" |> read_file_day18(1024)
  let path_len = dijkstra(pq.from_list([#(0, 0)], fn(_a, _b) { order.Eq }), dict.from_list([#(#(0, 0), 0)]), dict.from_list([]), dict.from_list([]), map, 71, set.from_list([]), #(70, 70))
  util.print_num("Day 18 (input)", path_len - 1)

  let corrupted_blocks = "day18.txt" |> read_file_all_day18
  let corr_p = find_unreachable(corrupted_blocks, 71, 1)
  io.print("Day 18 p2 (input): ")
  io.println(int.to_string(corr_p.0) <> "," <> int.to_string(corr_p.1))
}
