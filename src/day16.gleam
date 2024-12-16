import gleam/set
import gleam/io
import gleam/int
import gleam/dict
import gleam/string
import util
import gleam/list
import file_streams/file_stream as fs

type Map = dict.Dict(util.Point, String)
type Node = #(util.Point, util.Point)

fn print_map(map, at, end) {
  let keys = map |> dict.keys
  let ys = keys |> list.map(fn (key: util.Point) {
    key.1
  }) |> list.unique |> list.sort(int.compare)
  let xs = keys |> list.map(fn (key: util.Point) {
    key.0
  }) |> list.unique |> list.sort(int.compare)
  ys |> list.map(fn (y) {
    let line = xs |> list.map(fn (x) {
      case at == #(x, y) {
        True -> "S"
        _ -> {
          case end == #(x, y) {
            True -> "E"
            _ -> {
              case dict.get(map, #(x, y)) {
                Ok(v) -> v
                _ -> "?"
              }
            }
          }
        }
      }
    }) |> string.join("")
    io.println(line)
  })
}

fn read_file_day16(filename) -> #(Map, util.Point, util.Point) {
  let assert Ok(f) = fs.open_read(filename)
  let raw_map = util.read_loop(f, [])
  let map_with_start = raw_map
  |> list.take_while(fn (l) {
    !{l |> string.trim_end |> string.is_empty}
  }) |> list.index_map(fn (line, y) {
    line |> string.trim_end |> string.to_graphemes |> list.index_map(fn (c, x) {
      #(#(x, y), c)
    })
  }) |> list.flatten |> dict.from_list

  let assert Ok(start_point) = map_with_start
  |> dict.filter(fn (_k, v) {
    v == "S"
  })
  |> dict.keys
  |> list.first

  let assert Ok(end_point) = map_with_start
  |> dict.filter(fn (_k, v) {
    v == "E"
  })
  |> dict.keys
  |> list.first

  let map = map_with_start
    |> dict.delete(start_point)
    |> dict.insert(start_point, ".")
    |> dict.delete(end_point)
    |> dict.insert(end_point, ".")

  #(map, start_point, end_point)
}

fn dirs(dir) -> List(util.Point) {
  list.flatten([[dir],
    case dir {
      #(0, 1) | #(0, -1) -> [#(-1, 0), #(1, 0)]
      #(1, 0) | #(-1, 0) -> [#(0, 1), #(0, -1)]
      _ -> []
    }
  ])
}

fn point_free(p, map) -> Bool {
  case dict.get(map, p) {
    Ok(".") -> True
    _ -> False
  }
}

fn dfs(at, dir, score, map, e, visited: dict.Dict(util.Point, set.Set(util.Point))) -> Int {
  case at == e {
    True -> {
      score
    }
    False -> {
      dirs(dir) |> list.filter(fn (d) {
        let is_free = util.point_add(at, d) |> point_free(map)
        let is_visited = dict.has_key(visited, util.point_add(at, d) )
        is_free && !is_visited
      }) |> list.map(fn (d) {
        let new_score = score + 1 + case dir == d {
          True -> 0
          False -> 1000 // deer rotations are costly apparently
        }
        dfs(util.point_add(at, d), d, new_score, map, e, dict.insert(visited, at, set.from_list([dir])))
      }) |> list.fold(util.max_int, int.min)
    }
  }
}

fn get_or_default(dct: dict.Dict(Node, Int), node: Node, def: Int) {
  case dict.get(dct, node) {
    Ok(v) -> v
    _ -> def
  }
}

fn traverse(n: Node, prev: dict.Dict(Node, List(Node)), dist: dict.Dict(Node, Int)) {
  case dict.get(dist, n) {
    Ok(0) -> {
      [n.0]
    }
    _ -> {
      case dict.get(prev, n) {
        Ok(ancestors) -> {
          [n.0, ..{
            ancestors  |> list.index_map(fn(an, i) {
              traverse(an, prev, dist)
            }) |> list.flatten}
          ]
        }
        _ -> []
      }
    }
  }
}

fn dijkstra(q: List(Node), dist: dict.Dict(Node, Int), prev: dict.Dict(Node, List(Node)), map: Map, visited: set.Set(Node), e: util.Point) -> #(Int, Int) {
  case q {
    [first, ..rest] -> {
      let #(p, dir) = first
      case p == e {
        True -> {
          #(get_or_default(dist, #(p, dir), 0), traverse(#(p, dir), prev, dist) |> list.unique |> list.length)
        }
        False -> {
          let q_dist = get_or_default(dist, #(p, dir), util.max_int)
          // for each unvisited neighbour
          let ns = dirs(dir)
            |> list.filter(fn (d) {
              let is_free = util.point_add(p, d) |> point_free(map)
              let is_visited = set.contains(visited, #(util.point_add(p, d), d) )
              is_free && !is_visited
            })
          let #(new_dist, new_prev) = ns
            |> list.fold(#(dist, prev), fn (acc, d) {
              let #(cur_dist, cur_prev) = acc
              let alt = q_dist + 1 + case dir == d {
                True -> 0
                False -> 1000 // deer rotations are costly apparently
              }
              let v = #(util.point_add(p, d), d)
              let v_dist = get_or_default(dist, v, util.max_int)
              case alt < v_dist {
                True -> #(dict.insert(cur_dist, v, alt), dict.insert(cur_prev, v, [#(p, dir)]))
                False -> case alt == v_dist {
                  True -> {
                    let prevs = case dict.get(cur_prev, v) {
                      Ok(prevs) -> prevs
                      _ -> []
                    }
                    #(dict.insert(cur_dist, v, alt), dict.insert(cur_prev, v, [#(p, dir), ..prevs] |> list.unique))
                  }
                  False -> acc
                }
              }
            })
            let nns = ns |> list.map(fn (d) {
              #(util.point_add(p, d), d)
            })
            let sorted_q = list.flatten([rest, nns]) |> list.sort(fn(a, b) {
              int.compare(
                get_or_default(new_dist, a, util.max_int),
                get_or_default(new_dist, b, util.max_int)
              )
            })
            let new_visited = set.insert(visited, first)
            dijkstra(sorted_q, new_dist, new_prev, map, new_visited, e)
        }
      }
    }
    _ -> {
      #(util.max_int, util.max_int)
    }
  }
}

fn navigate(filename) {
  let #(map, start_point, end_point) = read_file_day16(filename)
  let start_node = #(start_point, #(1, 0))
  let #(shortest_length, all_shortest_count) = dijkstra([start_node], dict.from_list([#(start_node, 0)]), dict.from_list([]), map, set.from_list([]), end_point)
  #(shortest_length, all_shortest_count)
}

pub fn main() {
  let #(test_shortest, test_all_shortest_count) = "./test16.txt" |> navigate
  // this takes around 1-2 hours
  let #(shortest, all_shortest_count) = "./day16.txt" |> navigate

  util.print_num("Day 16 (test)", test_shortest)
  util.print_num("Day 16 (input)", test_all_shortest_count)
  util.print_num("Day 16 p2 (test)", test_all_shortest_count)
  util.print_num("Day 16 p2 (input)", all_shortest_count)
}
