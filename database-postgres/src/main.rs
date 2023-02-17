
#![allow(unused)]

use std::fs;
use sqlx::postgres::{PgPoolOptions,PgRow};
use sqlx::{FromRow, Row, Pool, Postgres};

pub type Db = Pool<Postgres>;

const SQL_DIR: &str = "src/sql/";
const SQL_CREATE: &str = "src/sql/00-create-ripple-schema.sql";
const SQL_TRIGGERS: &str = "src/sql/01-create-ripple-triggers.sql";

const DB_USER: &str = "badger";
const DB_PASS: &str = "badger";
const DB: &str = "dimsum";


#[derive(sqlx::FromRow)]
struct Dbcreated {
    id: i32
}

//Read SQL from a file to use in DB Creation
async fn read_sql_file(pool: &Pool<Postgres>, file: &str, delimiter: &str) -> Result<(),sqlx::Error> {

    let content = fs::read_to_string(file).map_err(| ex| {
        println!("Error reading {} (reason:{:?})", file, ex);
        ex
    })?;

    let sqls: Vec<&str> = content.split(delimiter).collect();

    for sql in sqls {
        println!("{sql}");
        match sqlx::query(&sql).execute(pool).await {
            Ok(..) => println!("Trigger Contents: "),
            Err(ex) => println!("Warning pexec triggers '{}' failed because: {}", file, ex),
        }
    }
    
    println!("Leaving {}...", file);
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

// Check to see if the 'library' table exists, if not we need to create our DB :D
async fn table_exists(pool: &Pool<Postgres>, schema_name: &str, table_name: &str) -> sqlx::Result<bool> {
    let exists: Option<bool> = sqlx::query_scalar(
        r#"
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = $1 AND table_name = $2
        )
        "#)
        .bind(schema_name)
        .bind(table_name)
        .fetch_one(pool)
        .await?;

    Ok(exists.unwrap_or(false))
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

    //Run test to see if the "library" table has already been created
    let table_name = "library";
    let schema_name = "public";
    let table_exists = table_exists(&pool, schema_name, table_name).await?;
    
    println!("WE CONNECTED TO THE DB!!");
    
// testread();

    if table_exists {
        println!("Table exists!");
    } else {
        println!("Table does not exist.");
        read_sql_file(&pool, SQL_CREATE, ";").await?;
        read_sql_file(&pool, SQL_TRIGGERS, "--").await?;
        println!("IF YOU DO NOT ANY ERRORS, LOOKS LIKE WE MADE THE TABLES :D");
    }

    Ok(())
}