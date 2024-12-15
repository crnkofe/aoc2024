import gleam/io
import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import file_streams/file_stream as fs

fn move_around(robot: List(util.Point), steps: Int, w: Int, h: Int) -> util.Point {
  case robot {
    [p, v] -> {
      let xadj = {p.0 + steps * v.0} % w
      let yadj = {p.1 + steps * v.1} % h
      #(
        case xadj < 0 {
          True -> xadj + w
          False -> xadj
        },
      case yadj < 0 {
        True -> yadj + h
        False -> yadj
      }
      )
    }
    _ -> #(-1, -1)
  }
}

fn is_mid(p: util.Point, w: Int, h: Int) {
  {p.0 == w / 2} || {p.1 == h / 2}
}

fn print(lst, step, w, h) {
  io.print("Step ")
  io.println(int.to_string(step))
  list.range(0, h-1) |> list.map(fn (y) {
    let line = list.range(0, w-1) |> list.map(fn (x) {
      case list.contains(lst, #(x, y)) {
        True -> "o"
        False -> "."
      }
    }) |> string.join("")
    io.println(line)
  })
}

fn quadrants(lst, w, h) {
  let partitioned = lst |> list.filter(fn(p) {
    !is_mid(p, w, h)
  }) |> list.group(fn (p) {

    let quadrant = case p.0 / {w / 2} {
      0 -> {
        case p.1 / {h / 2} {
          0 -> 0
          _ -> 1
        }
      }
      _ -> {
        case p.1 / {h / 2} {
          0 -> 2
          _ -> 3
        }
      }
    }
    quadrant
  }) |> dict.values |> list.map(list.length)

  partitioned |> list.fold(1, int.multiply)
}

fn read_file_day14(filename) -> List(List(util.Point)) {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, [])
  |> list.filter(fn (line) {
    !{line |> string.trim_end |> string.is_empty}
  })
  |> list.map(fn (line) {
    line |> string.trim_end
    |> string.replace("p=", "")
    |> string.replace("v=", "")
    |> string.split(" ")
    |> list.map(fn(raw_pair) {
      let raw_p = string.split(raw_pair, ",") |> list.map(fn (s) {
        let assert Ok(n) = int.parse(s)
        n
      })
      case raw_p {
        [a, b] -> #(a, b)
        _ -> #(util.max_int, util.max_int)
      }
    })
  })
}

pub fn main() {
  let tw = 11
  let th = 7

  util.print_num("Day 14 (test)",
     "./test14.txt" |> read_file_day14 |> list.map(fn(p) {
       move_around(p, 100, tw, th)
     }) |> quadrants(tw, th)
  )

  let w = 101
  let h = 103

  let init = "./day14.txt" |> read_file_day14
  util.print_num("Day 14 (test)", init |> list.map(fn(p) {
    move_around(p, 100, w, h)
  }) |> quadrants(w, h)
  )

  list.range(0, 10000) |> list.each(fn (step) {
     init |> list.map(fn(p) {
       move_around(p, step, w, h)
     }) |> print(step, w, h)
  })
}
