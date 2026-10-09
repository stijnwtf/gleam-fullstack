import gleam/dynamic/decode
import gleam/http.{Delete, Get, Patch, Post}
import gleam/int
import gleam/json
import gleam/option
import gleam/result
import server/store
import server/web.{type Context}
import shared/task
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", "health"] -> wisp.ok() |> wisp.string_body("ok")
    ["api", "tasks"] -> tasks(req, ctx)
    ["api", "tasks", id] -> task_by_id(req, ctx, id)
    ["api", ..] -> wisp.not_found()
    _ -> static(req, ctx)
  }
}

// API -------------------------------------------------------------------------

fn tasks(req: Request, ctx: Context) -> Response {
  case req.method {
    Get ->
      store.all(ctx.store)
      |> task.list_to_json
      |> json.to_string
      |> wisp.json_response(200)

    Post -> {
      use body <- wisp.require_json(req)
      case decode_and_validate(body) {
        Ok(title) ->
          store.create(ctx.store, title)
          |> task.to_json
          |> json.to_string
          |> wisp.json_response(201)
        Error(message) -> error_response(422, message)
      }
    }

    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn task_by_id(req: Request, ctx: Context, id: String) -> Response {
  use id <- with_int_id(id)

  case req.method {
    Patch -> {
      use body <- wisp.require_json(req)
      case decode.run(body, task.update_decoder()) {
        Ok(task.UpdateTask(completed:)) ->
          case store.set_completed(ctx.store, id, completed) {
            Ok(updated) ->
              updated
              |> task.to_json
              |> json.to_string
              |> wisp.json_response(200)
            Error(Nil) -> wisp.not_found()
          }
        Error(_) -> error_response(422, "Expected {\"completed\": bool}")
      }
    }

    Delete ->
      case store.delete(ctx.store, id) {
        Ok(Nil) -> wisp.no_content()
        Error(Nil) -> wisp.not_found()
      }

    _ -> wisp.method_not_allowed([Patch, Delete])
  }
}

fn decode_and_validate(body) -> Result(String, String) {
  use task.CreateTask(title:) <- result.try(
    decode.run(body, task.create_decoder())
    |> result.replace_error("Expected {\"title\": string}"),
  )
  task.validate_title(title)
}

fn with_int_id(id: String, next: fn(Int) -> Response) -> Response {
  case int.parse(id) {
    Ok(id) -> next(id)
    Error(Nil) -> wisp.not_found()
  }
}

fn error_response(status: Int, message: String) -> Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> wisp.json_response(status)
}

// STATIC FILES ----------------------------------------------------------------

/// Serves the compiled client from `priv/static`. Unknown paths fall back to
/// `index.html` so client-side routing keeps working on refresh.
fn static(req: Request, ctx: Context) -> Response {
  use <- wisp.serve_static(req, under: "/", from: ctx.static_directory)
  case req.method {
    Get ->
      wisp.ok()
      |> wisp.set_header("content-type", "text/html; charset=utf-8")
      |> wisp.set_body(wisp.File(
        path: ctx.static_directory <> "/index.html",
        offset: 0,
        limit: option.None,
      ))
    _ -> wisp.not_found()
  }
}
