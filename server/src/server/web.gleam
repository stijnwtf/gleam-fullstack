import gleam/erlang/process.{type Subject}
import server/store
import wisp

pub type Context {
  Context(store: Subject(store.Message), static_directory: String)
}

/// Middleware that runs for every request.
pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}
