import gleam/float
import gleam/string
import util
import gleam/int
import gleam/list
import file_streams/file_stream as fs

const max_int =  9007199254740991

fn read_file_day13(filename) -> List(List(util.Point)) {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, [])
  |> list.filter(fn (line) {
    !{line |> string.trim_end |> string.is_empty}
  })
  |> list.map(fn (line) {
    let nums = line |> string.trim_end
      |> string.replace("Button A: X+", "")
      |> string.replace("Button B: X+", "")
      |> string.replace("Prize: X=", "")
      |> string.replace("Y+", "")
      |> string.replace("Y=", "")
      |> string.split(", ")
      |> list.map(fn(sint) {
        let assert Ok(res) = int.parse(sint)
        res
      })
    #(util.assert_nth(nums, 0), util.assert_nth(nums, 1))
  }) |> list.sized_chunk(3)
}


fn min_token_cost_b(p: util.Point, b, move_b, prize: util.Point) -> Int {
  case move_b > 100 || p.0 > prize.0 || p.1 > prize.1 {
    True -> max_int
    False -> {
      case p == prize {
        True -> move_b
        False -> {
          min_token_cost_b(util.point_add(p, b), b, move_b + 1, prize)
        }
      }
    }
  }
}

fn min_token_cost(move_a, a, b, prize) -> #(Int, Int) {
  case move_a > 100 {
    True -> #(max_int, max_int)
    False -> {
      let min_b = min_token_cost_b(util.point_mul(a, move_a), b, 0, prize)
      let #(alt_a, alt_b) = min_token_cost(move_a + 1, a, b, prize)
      case {3 * alt_a + alt_b} < {3 * move_a + min_b} {
        True -> #(alt_a, alt_b)
        False -> #(move_a, min_b)
      }
    }
  }
}

fn play_machine(l: List(util.Point)) -> Int {
  case l {
    [a, b, prize] -> {
      let #(move_a, move_b) = min_token_cost(0, a, b, prize)
      case move_a != max_int && move_b != max_int {
        True -> move_a * 3 + move_b
        False -> 0
      }
    }
    _ -> 0
  }
}

fn is_solution(a: util.Point, b: util.Point, pi: util.Point, prize: util.Point, fa, fb) {
  case {pi.0 >= 0} && {pi.0 <= prize.0} &&
       {pi.1 >= 0} && {pi.1 <= prize.1} {
    True -> {
      case pi.0 % a.0 == 0 && pi.1 % a.1 == 0 &&
      { prize.0 - pi.0 } % b.0 == 0 && { prize.1 - pi.1 } % b.1 == 0 {
        True -> {
          let mul3 = {pi.0 / a.0}
          let mul1 = { prize.1 - pi.1 } / b.1
          mul3 * fa + mul1 * fb
        }
        False -> {
          0
        }
      }
    }
    False -> 0
  }
}

fn calc_intersect(a: util.Point, b: util.Point, prize: util.Point, fa, fb) {
  // We are looking for an intersection of two lines
  // there are many possible solutions but two degenerate cases
  // either users presses button A N times and B M-times or vice-versa

  // If we imagine user always only doing consecutive A and/or B then
  // What we are looking for is line intersection where line only exists
  // at discrete points.

  // case 1:
  // first line will start at 0, 0 and moves by vector A (y = a.1/a.0 * x)
  // second line goes through finish line (prize) y = b.1/b.0 * x + N
  // to calculate N insert prize N = prize.1 - b.1/b.0 *
  // second line

  // user presses only button A first then B
  let ka = int.to_float(a.1) /. int.to_float(a.0)
  let kb = int.to_float(b.1) /. int.to_float(b.0)
  // y = kx + N
  let bn = int.to_float(prize.1) -. kb *. int.to_float(prize.0)
  // line equality: ax + c = bx + d
  // a.1/a.0 * x = b.1/b.0 * x + N
  // x * (a.1/a.0 - b.1/b.0) = N
  // x = N / (a.1/a.0 - b.1/b.0)
  let intersect_x = bn /. {ka -. kb}
  let intersect_y = ka *. intersect_x

  let pi = #(float.round(float.floor(intersect_x)), float.round(float.floor(intersect_y)))
  [#(0, 0), #(0, 1), #(1, 0), #(1, 1)] |> list.fold(0, fn(res, x) {
    int.max(res, is_solution(a, b, util.point_add(pi, x), prize, fa, fb))
  })
}

fn play_machine_2(l: List(util.Point), n) -> Int {
  case l {
    [a, b, init_prize] -> {
      let prize = util.point_add(init_prize, #(n, n))
      int.min(
        calc_intersect(a, b, prize, 3, 1),
        calc_intersect(b, a, prize, 1, 3)
      )
  }
    _ -> 0
  }
}

pub fn main() {
  util.print_num("Day 13 (test)", "./test13.txt"
    |> read_file_day13
    |> list.map(play_machine)
    |> list.fold(0, int.add)
  )

  util.print_num("Day 13 (input)", "./day13.txt"
    |> read_file_day13
    |> list.map(play_machine)
    |> list.fold(0, int.add)
  )

  util.print_num("Day 13 p2 (test)", "./test13.txt"
    |> read_file_day13
    |> list.map(fn (x) {
      play_machine_2(x, 10000000000000)
    })
    |> list.fold(0, int.add)
  )

  util.print_num("Day 13 p2 (input)", "./day13.txt"
  |> read_file_day13
  |> list.map(fn (x) {
    play_machine_2(x, 10000000000000)
  })
  |> list.fold(0, int.add)
  )
}
