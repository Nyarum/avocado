CREATE TABLE accounts (
	id serial PRIMARY KEY,
	username VARCHAR ( 50 ) UNIQUE NOT NULL,
	password VARCHAR ( 100 ) NOT NULL,
	pincode VARCHAR ( 100 ),
	created_at TIMESTAMP NOT NULL,
	updated_at TIMESTAMP NOT NULL,
    last_login TIMESTAMP
);

CREATE TABLE characters (
	id serial PRIMARY KEY,
	account_id INT references accounts(id),
	name VARCHAR(50) UNIQUE NOT NULL,
	job VARCHAR(50),
	level INT,
	look JSONB NOT NULL,
	created_at TIMESTAMP NOT NULL,
	updated_at TIMESTAMP NOT NULL
);