import gleam/set
import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import file_streams/file_stream as fs

type Map = dict.Dict(util.Point, String)

const directions = [#(0, 1), #(1, 0), #(0, -1), #(-1, 0)]

fn read_file_day12(filename) -> Map {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.index_map(fn (line, y) {
    line |> string.trim_end |> string.to_graphemes |> list.index_map(fn (c, x) {
        #(#(x, y), c)
    })
  }) |> list.flatten |> dict.from_list
}

fn next(open, det, map, region: set.Set(util.Point)) -> set.Set(util.Point) {
  case open {
    [first, ..rest] -> {
      let new = directions
      |> list.map(fn (dir) { util.point_add(first, dir)})
      |> list.filter(fn (np) {
        case dict.get(map, np) {
          Ok(npv) -> {
            !list.contains(open, np) && !set.contains(region, np) && npv == det
          }
          _ -> False
        }
      })
      next(list.flatten([rest, new]), det, map, set.insert(region, first))
    }
    _ -> region
  }
}

fn count_fences(region: set.Set(util.Point)) -> Int {
  region |> set.to_list |> list.map(fn (p) {
    directions
    |> list.map(fn (dir) { util.point_add(p, dir)})
    |> list.filter(fn (np) {
      !set.contains(region, np)
    }) |> list.length
  }) |> list.fold(0, int.add)
}

fn point_exists(map, p, val) {
   case dict.get(map, p) {
     Ok(res) -> res == val
     _ -> False
   }
}

fn extend(p: util.Point, map, region: List(util.Point), val, check_vec, direction) {
  let new_point = util.point_add(p, direction)
  case list.contains(region, new_point) && !point_exists(map, util.point_add(new_point, check_vec), val) {
    True -> list.flatten([[new_point], extend(new_point, map, region, val, check_vec, direction)])
    False -> []
  }
}

fn count_horizontal_sides(map, region: List(util.Point), val, check_vec) {
  // idea grow edges - pick a point find neighbours recursively
  case region {
    [first, ..rest] -> {
      case point_exists(map, util.point_add(first, check_vec), val) {
        True -> count_horizontal_sides(map, rest, val, check_vec)
        False -> {
          // extend point into a direction until hitting an empty space
          let extend_forward = extend(first, map, region, val, check_vec, #(1, 0))
          let extend_backward = extend(first, map, region, val, check_vec, #(-1, 0))
          let edge = list.flatten([extend_backward, [first], extend_forward])
          let remainder = rest |> list.filter(fn (p) {
            !list.contains(edge, p)
          })
          1 + count_horizontal_sides(map, remainder, val, check_vec)
        }
      }
    }
    [] -> 0
  }
}


fn count_vertical_sides(map, region: List(util.Point), val, check_vec) {
  // idea grow edges - pick a point find neighbours recursively
  case region {
    [first, ..rest] -> {
      case point_exists(map, util.point_add(first, check_vec), val) {
        True -> count_vertical_sides(map, rest, val, check_vec)
        False -> {
          // extend point into a direction until hitting an empty space
          let extend_forward = extend(first, map, region, val, check_vec, #(0, 1))
          let extend_backward = extend(first, map, region, val, check_vec, #(0, -1))
          let edge = list.flatten([extend_backward, [first], extend_forward])
          let remainder = rest |> list.filter(fn (p) {
            !list.contains(edge, p)
          })
          1 + count_vertical_sides(map, remainder, val, check_vec)
        }
      }
    }
    [] -> 0
  }
}

fn paint_subset(map: Map) -> #(Map, Int) {
  case map |> dict.keys |> list.first {
    Ok(first_point) -> {
      let assert Ok(val) = dict.get(map, first_point)
      let region = next([first_point], val, map, set.from_list([]))
      let submap = map |> dict.filter(fn (k, _v) {
        !set.contains(region, k)
      })
      #(submap, set.size(region) * count_fences(region))
    }
    Error(_) -> #(dict.from_list([]), 0)
  }
}

fn paint(map) -> Int {
  case dict.is_empty(map) {
    True -> 0
    False -> {
      let #(remainder_map, new_sum) = paint_subset(map)
      new_sum + paint(remainder_map)
    }
  }
}

fn paint_subset_2(map: Map) -> #(Map, Int) {
  case map |> dict.keys |> list.first {
    Ok(first_point) -> {
      let assert Ok(val) = dict.get(map, first_point)
      let region = next([first_point], val, map, set.from_list([]))
      let submap = map |> dict.filter(fn (k, _v) {
        !set.contains(region, k)
      })
      let c1 = count_horizontal_sides(map, region |> set.to_list, val, #(0, 1))
      let c2 = count_horizontal_sides(map, region |> set.to_list, val, #(0, -1))
      let c3 = count_vertical_sides(map, region |> set.to_list, val, #(1, 0))
      let c4 = count_vertical_sides(map, region |> set.to_list, val, #(-1, 0))
      let count_sides = c1 + c2 + c3 + c4
      #(submap, set.size(region) * count_sides)
    }
    Error(_) -> #(dict.from_list([]), 0)
  }
}

fn paint_2(map) -> Int {
  case dict.is_empty(map) {
    True -> 0
    False -> {
      let #(remainder_map, new_sum) = paint_subset_2(map)
      new_sum + paint_2(remainder_map)
    }
  }
}

pub fn main() {
  util.print_num("Day 12 (test)", "./test12.txt" |> read_file_day12 |> paint)
  util.print_num("Day 12 (input)", "./day12.txt" |> read_file_day12 |> paint)

  util.print_num("Day 12 p2 (test)", "./test12.txt" |> read_file_day12 |> paint_2)
  util.print_num("Day 12 p2 (input)", "./day12.txt" |> read_file_day12 |> paint_2)
}
