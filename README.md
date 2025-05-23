# database_setup

### Install Homebrew if not already
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


## Directory Structure
- Sample data:
```
FAIRtrain-schema/
├── data/           # CSV files
├── dictionary/     # JSON metadata files
├── schema.json     # Shared schema definition
```

---

### Create .env file
Create a `.env` file with the following content:
```env
DB_USER=mac_username
DB_NAME=fairtrain
MONGO_DB=fairtrain
DATA_PATH=path_to_data_files_csv_files
DICT_PATH=path_to_dictionary_files_json_files
```


## PostgreSQL Setup - Mac via homebrew

### 1. Install PostgreSQL (macOS)
```bash
brew install postgresql
brew services start postgresql
```

### 2. Create the database
```bash
createdb -U $(whoami) fairtrain 
```
- fairtrain is the name of the database

### 4. Run the PostgreSQL setup script
```bash
chmod +x setup_postgres.sh
./setup_postgres.sh
```

- This script:
  - Creates a `samples` table using `schema.json`
  - Loops through all CSVs in `$DATA_PATH` and imports them into the table

- To verify the data was correctly inserted:
```
psql -U $(whoami) -d fairtrain
SELECT * FROM samples LIMIT 5;
```
    -   This shows the top 5 records in the database

### 5. View in pgAdmin (optional)
Install pgAdmin via website: https://www.pgadmin.org/download/pgadmin-4-macos/

- Open pgAdmin
- Click add New server on the dashboard
- Add a name for the server in the name box in general tab
- Go to connection tab
    - hostname / address: `localhost`
    - port: 5432
    - maintance database: `postgres`
    - username: your_mac_username 
- Go to Object Explorer tab on the left side
- Click on server that you created (the one that was named)
- Click on `schemas`, then `tables`, then `samples`
- Right-click samples tab on the object explorer tab
    - Click on View/Edit Data then click on All Rows
    - Click on the Data Output tab at the bottom of the page if not already opened


## MongoDB Setup - Mac via homebrew

### 1. Install MongoDB
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb/brew/mongodb-community
```

### 2. Extend `.env`
Add to your `.env`:
```env
MONGO_DB="monogo database name"
```

### 3. Run the MongoDB setup script
```bash
chmod +x setup_mongo.sh
./setup_mongo.sh
```

- This script:
  - Creates a validated `samples` collection using `schema.json`
  - Imports all CSVs from `$DATA_PATH` into individual collections
  - Imports all JSONs from `$DICT_PATH` into a shared `dictionaries` collection

### 4. Verify in `mongosh`
```bash
mongosh
use fairtrain
db.samples.findOne()
db.dictionaries.find().limit(3)
```
This shows the first 3 records on mongobd

### 5. View on mongo compass (optional)
Install MongoDB Compass from website: https://www.mongodb.com/try/download/compass

- Open mongodb compass
- Go to connections tab on the left-hand side
- Hover over `localhost:27017` until CONNECT button appears, then click on it
- Click on the database that you created, in this example, it would be fairtrain
