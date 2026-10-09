import client/api
import client/model.{type Model, type Msg}
import client/view
import lustre
import lustre/effect.{type Effect}

pub fn main() -> Nil {
  let app = lustre.application(init, model.update, view.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(model.init(), api.list_tasks(model.ApiReturnedTasks))
}
