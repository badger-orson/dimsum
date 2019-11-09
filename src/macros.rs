extern crate diesel;

use parking_lot::Mutex;

pub static DB_LOCK: Mutex<()> = Mutex::new(());

#[macro_export]
macro_rules! run_test {
    (|$client:ident| $block:expr) => {{
        let _lock = DB_LOCK.lock();
        let rocket = rocket_pad();
        let $client = Client::new(rocket).expect("Rocket client");

        $block
    }};
}
