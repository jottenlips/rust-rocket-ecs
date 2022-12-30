#[macro_use] extern crate rocket;
use rocket::http::Status;
use rocket::response::{content, status};

#[get("/")]
fn hello() -> status::Custom<content::RawJson<&'static str>> {
    status::Custom(Status::Accepted, content::RawJson("{ \"hello\": \"world\" }"))
}

#[get("/health")]
fn health() -> status::Custom<content::RawJson<&'static str>> {
    status::Custom(Status::Accepted, content::RawJson("{ \"hello\": \"world\" }"))
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![hello, health])
}