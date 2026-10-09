//// The `Task` type and its JSON codecs. This module compiles to both Erlang
//// (server) and JavaScript (client), so the API contract lives in one place
//// and the compiler checks both sides against it.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/string

pub type Task {
  Task(id: Int, title: String, completed: Bool)
}

pub const max_title_length = 120

pub fn to_json(task: Task) -> Json {
  json.object([
    #("id", json.int(task.id)),
    #("title", json.string(task.title)),
    #("completed", json.bool(task.completed)),
  ])
}

pub fn decoder() -> Decoder(Task) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use completed <- decode.field("completed", decode.bool)
  decode.success(Task(id:, title:, completed:))
}

pub fn list_to_json(tasks: List(Task)) -> Json {
  json.array(tasks, to_json)
}

pub fn list_decoder() -> Decoder(List(Task)) {
  decode.list(decoder())
}

// REQUESTS --------------------------------------------------------------------

/// Body of `POST /api/tasks`.
pub type CreateTask {
  CreateTask(title: String)
}

pub fn create_to_json(create: CreateTask) -> Json {
  json.object([#("title", json.string(create.title))])
}

pub fn create_decoder() -> Decoder(CreateTask) {
  use title <- decode.field("title", decode.string)
  decode.success(CreateTask(title:))
}

/// Body of `PATCH /api/tasks/:id`.
pub type UpdateTask {
  UpdateTask(completed: Bool)
}

pub fn update_to_json(update: UpdateTask) -> Json {
  json.object([#("completed", json.bool(update.completed))])
}

pub fn update_decoder() -> Decoder(UpdateTask) {
  use completed <- decode.field("completed", decode.bool)
  decode.success(UpdateTask(completed:))
}

// VALIDATION ------------------------------------------------------------------

/// Shared by the client (instant feedback) and the server (the real check).
pub fn validate_title(title: String) -> Result(String, String) {
  let title = string.trim(title)
  case string.length(title) {
    0 -> Error("Title can't be empty")
    n if n > max_title_length ->
      Error(
        "Title can be at most "
        <> string.inspect(max_title_length)
        <> " characters",
      )
    _ -> Ok(title)
  }
}
