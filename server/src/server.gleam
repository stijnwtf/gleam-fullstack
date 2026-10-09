import envoy
import gleam/erlang/application
import gleam/erlang/process
import gleam/int
import gleam/result
import mist
import server/router
import server/store
import server/web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let port =
    envoy.get("PORT")
    |> result.try(int.parse)
    |> result.unwrap(8000)

  // Set SECRET_KEY_BASE in production so signed cookies survive restarts.
  let secret_key_base =
    envoy.get("SECRET_KEY_BASE")
    |> result.lazy_unwrap(fn() { wisp.random_string(64) })

  let assert Ok(priv) = application.priv_directory("server")
  let assert Ok(store) = store.start()
  let ctx = Context(store:, static_directory: priv <> "/static")

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start

  process.sleep_forever()
}
