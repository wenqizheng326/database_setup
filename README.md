# database_setup

## Directory Structure
- Sample data:
```
FAIRtrain-schema/
├── data/           # CSV files
├── dictionary/     # JSON metadata files
├── schema.json     # Shared schema definition
```

---

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

### 3. Create .env file
Create a `.env` file with the following content:
```env
DB_USER="comp username"
DB_NAME="database name"
```

### 4. Run the PostgreSQL setup script
```bash
chmod +x setup_postgres.sh
./setup_postgres.sh
```

- This script:
  - Creates a `samples` table using `schema.json`
  - Loops through `data/*.csv` and imports into the table

### 5. View in pgAdmin (optional)
- Open pgAdmin
- Connect to `localhost` > `fairtrain` > `schemas` > `tables` > `samples`

---

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
  - Imports all `data/*.csv` into their own collections
  - Imports all `dictionary/*.json` into a shared `dictionaries` collection

### 4. Verify in `mongosh`
```bash
mongosh
use fairtrain
db.samples.findOne()
db.dictionaries.find().limit(3)
```
This shows the first 3 records on mongobd

