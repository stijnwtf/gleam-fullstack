import gleam/json
import gleeunit
import shared/task.{Task}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn task_json_roundtrip_test() {
  let original = Task(id: 1, title: "Write tests", completed: True)
  let assert Ok(decoded) =
    original
    |> task.to_json
    |> json.to_string
    |> json.parse(task.decoder())
  assert decoded == original
}

pub fn validate_title_trims_test() {
  assert task.validate_title("  Buy milk  ") == Ok("Buy milk")
}

pub fn validate_title_rejects_empty_test() {
  let assert Error(_) = task.validate_title("   ")
}

pub fn validate_title_rejects_too_long_test() {
  let assert Error(_) = task.validate_title(string_of_length(121))
}

fn string_of_length(n: Int) -> String {
  case n {
    0 -> ""
    _ -> "a" <> string_of_length(n - 1)
  }
}
