
#![allow(unused)]

use std::fs;
use sqlx::postgres::{PgPoolOptions,PgRow};
use sqlx::{FromRow, Row, Pool, Postgres};

pub type Db = Pool<Postgres>;

const SQL_DIR: &str = "src/sql/";
const SQL_RECREATE: &str = "src/sql/00-create-ripple-schema.sql";

const DB_USER: &str = "badger";
const DB_PASS: &str = "badger";
const DB: &str = "dimsum";


#[derive(sqlx::FromRow)]
struct Dbcreated {id: i32}
//create the Database from a file
async fn create_schema_db(db: &Db, file: &str) -> Result<(), sqlx::Error> {
    
    let content = fs::read_to_string(file).map_err(|ex| {
        println!("Error reading {} (cause: {:?} )", file, ex);
        ex
    })?;
// How do I skip if there is an error.., Obviously this does not exist yet...so its null...HMMM
    let mut is_created = sqlx::query_as::<_,Dbcreated>(
        r#"SELECT id FROM dbcreated"#
    ).fetch_one(db).await?;

    println!("IS DB Created already? {}", is_created.id);

    if is_created.id == 0 {
        // Split the string at ";" then move to next sql statement store in vector
        let sqls: Vec<&str> = content.split(";").collect();

        for sql in sqls {
            println!("{sql}");
            match sqlx::query(&sql).execute(db).await {
                
                Ok(_) => println!("FILE CONTENTS: "),
                Err(ex) => println!("WARNING pexec sqlfile '{}' Failed cause: {}",file, ex),
            }
        }
        } else {
            println!("DB is created already {}, not recreating", is_created.id);
    }

    Ok(())
}

fn create_connection_string(user: &str, pass: &str, database: &str) -> String {
    let mut connection_string: String = "postgresql://".to_string(); 
    connection_string.push_str(user);
    connection_string.push_str(":");
    connection_string.push_str(pass);
    connection_string.push_str("@0.0.0.0:5432/");
    connection_string.push_str(database);
   return connection_string;
}


#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {


    let connection = create_connection_string(DB_USER,DB_PASS,DB);

    println!("{}", connection);
        //Find current Directory
    println!("{}", std::env::current_dir().unwrap().display());
    //Create a Connection
    let pool = PgPoolOptions::new()
        .max_connections(20)
        .connect(&connection)
        .await?;

    //After connecting to the DB ATTEMPT to run a select statement 

    
    println!("WE CONNECTED TO THE DB!!");
    
// testread();
    create_schema_db(&pool, SQL_RECREATE).await?;

    println!("IF YOU DO NOT ANY ERRORS, LOOKS LIKE WE MADE THE TABLES :D");
    Ok(())
}