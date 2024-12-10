import gleam/set
import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

fn next(p, map, map_size) -> List(util.Point) {
  let directions = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]
  directions
    |> list.map(fn (dir) { util.point_add(p, dir)})
    |> list.filter(fn (np) {
      util.point_in_map(np, map_size)
  })
    |> list.filter(fn (np) {
      let assert Ok(pdata) = dict.get(map, p)
      case dict.get(map, np) {
        Ok(n) -> pdata + 1 == n
        _ -> False
      }
  })
}

fn dfs (p, rev_path: List(util.Point), visited, map, map_size) -> #(List(List(util.Point)), List(util.Point)) {
  case dict.get(map, p) {
    Ok(9) -> #([rev_path], [p])
    Ok(_) -> {
      let results = next(p, map, map_size) |> list.map(fn (n) {
        dfs(n, [p, ..rev_path], set.insert(visited, p), map, map_size)
      })
      let paths = results
        |> list.map(fn (x) { x.0 })
        |> list.flatten
        |> list.filter(fn (path) { !list.is_empty(path) })

      let unique_goals = results
        |> list.map(fn (x) { x.1 })
        |> list.flatten
      #(paths, unique_goals)
    }
    _ -> #([[]], [])
  }
}

fn read_file_day10(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let map = util.read_loop(f, []) |> list.index_map(fn (line, y) {
    line |> string.trim_end |> string.to_graphemes |> list.index_map(fn (c, x) {
      case int.parse(c) {
        Ok(n) -> #(#(x, y), n)
        _ -> #(#(0, 0), -1)
       }
    }) |> list.filter(fn (x) { x.1 >= 0})
  }) |> list.flatten |> dict.from_list
  let map_size = filename |> map_size
  let starting_points = map |> dict.filter(fn (_k, v) {
    v == 0
  }) |> dict.keys
  let results = starting_points |> list.map(fn (point) {
    dfs(point, [], set.from_list([]), map, map_size)
  })
  let part1 = results |> list.map(fn (r) {
    r.1 |> list.unique |> list.length
  })
  let part0 = results |> list.map(fn (r) { r.0 })
  #(
    part1 |> list.fold(0, int.add),
    part0 |> list.flatten |> list.length
  )
}

fn map_size(filename) -> Int {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.length
}

pub fn main() {
  let #(test_endings, test_paths) = "./test10_1.txt" |> read_file_day10
  util.print_num("Day 10 (test)", test_endings)
  util.print_num("Day 10 p2 (test)", test_paths)

  let #(endings, paths) = "./day10.txt" |> read_file_day10
  util.print_num("Day 10 (input)", endings)
  util.print_num("Day 10 p2 (input)", paths)
}
