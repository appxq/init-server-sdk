# InitServerSDK

Builder Tool https://builder.initcraft.com/
Use with https://github.com/appxq/init-starter-kit

- Fastify Framework
- MongoDB
- NodeJS

Feature

- user system (login/logout)
- RBAC
- WebSocket
- Notify system
- CRUD SQL to NoSQL
- Dynamic API (build in initCraft)
- Dynamic Rerport (build in initCraft)
- Dynamic SQL (build in initCraft)
- Dynamic Apps (build in initCraft)
- Dynamic Form (build in initCraft)
- Migrate/Rollback update DB
- Dynamic Setting Config
- Files Manage
- Dynamic import data
- Dynamic export data
- SDForm API
- Google OAuth2
- Two-Factor
- Support google cloud run https://console.cloud.google.com/

## nodejs install

```
npm i
```

```
npm install pm2 -g
```

## update last version

```
git pull origin main
```

## mongoDB install

```
brew tap mongodb/brew
brew update
brew install mongodb-community@8.0
```

```
brew services start mongodb/brew/mongodb-community
brew services stop mongodb/brew/mongodb-community
brew services restart mongodb/brew/mongodb-community
brew services list
```

## mongoDB add User

```
mongosh
use admin
```

```
db.createUser(
    {
        user: "admin",
        pwd: "1234",
        roles: [ { role: "root", db: "admin" }, "readWriteAnyDatabase" ]
    }
)
```

```
db.createUser(
    {
        user: "sdbuilder",
        pwd: "123456",
        roles: [ { role: "readWrite", db: "init_sdk" }, "readWriteAnyDatabase" ]
    }
)
```

## mongoDB authorization conf

```
nano /opt/homebrew/etc/mongod.conf
```

security:
authorization: enabled

## .env

```
SERVICE_NAME = 'InitServerSDK'
SERVICE_VERSION = '1.5.0'
#SERVICE_DESCRIPTION = 'Documentation the InitServerSDK'
ASSETS_PATH = 'assets/'
HOST = 'localhost'
FRONTEND_URL = "http://localhost:5173"
DOMAIN_URL = "http://localhost:3005"
MONGODB_URL = "mongodb://localhost:27017"
MONGODB_NAME = "dbtest"
MONGODB_USERNAME = "admin"
MONGODB_PASSWORD = "1234"
PGDB_ENABLE = 0
PGDB_HOST = 'localhost'
PGDB_PORT = 5432
PGDB_NAME = 'postgres'
PGDB_USERNAME = 'root'
PGDB_PASSWORD = ''
JWT_SECRET = "_Your_Secret_"
APP_NAME = "Initcraft"
APP_URL = "https://api.initcraft.com,https://builder.initcraft.com,http://localhost:5174"
APP_MAXSIZE = 10
MAILER_HOST = "smtp.gmail.com"
MAILER_PORT = 465
MAILER_SECURE = "true"
MAILER_USER = "admin@gmail.com"
MAILER_PASSWORD = "123456"
MAILER_FROM = "Admin <admin@gmail.com>"
WS_MAX = 1048576
LOGIN_LIMIT = 0
LOGIN_EXPIRES = 86400000
PRIVATE_KEY = "---Optional---"
PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJUKaPfUKzZtBiKOsKYYGCZCFr
EJEOZ+q/iJBak+bXAN9HVvlL/9u+rNy+HlEtWJAffA2MIXkXV8lzAqeMFmjjee/N
FDOtUsg8r6dqxCMULJpEnZ2ou370CL+XDlxn3oKorwM7LPTe2qr1DTvwVvLJx2hl
tjverk8X5A9+IBcvMQIDAQAB
-----END PUBLIC KEY-----"
REGISTER_ID = '--My License ID--'
OAUTH2_ID = '_google_id_'
OAUTH2_SECRET = '_google_secret_'
```

## CORS setup

```
APP_URL = "https://api.initcraft.com,https://builder.initcraft.com,[You api server]"
```

## Run migrate

```
npm run migrate
```

```
npm run rollback
```

## Run server

```
npm run dev
```

```
npm run start
```

## server manage https://pm2.keymetrics.io/

```
pm2 monit
```

```
pm2 list
```

```
pm2 stop
```

```
pm2 restart
```

```
pm2 delete
```

```
pm2 kill
```

## deploy to google cloud

```
brew install --cask google-cloud-sdk
```

```
gcloud auth login
```

```
gcloud run deploy --source .
```

### Deploy Error(does not have permission)

- IAM & Admin/IAM->Grant access
- Principal for Error mgs
- add roles Cloud Build Service Agent, Storage Object Viewer
- Save and new deploy

### Create service connect github (deploy by github)

- Cloud run->Services->Connect to repo
- select project and config
- create
- Services->Edit & deploy new revision->Variables & Secrets
- Click Deploy

## Google cloud config

### Variables Setup (env)

- Services->Edit & deploy new revision->Variables & Secrets
- Click Deploy

### Asset setup

- Cloud storage->Buckets (create and copy files, folder you project)

### Mount bucket

- Cloud run->Services->select you service->Edit & deploy new revision-> Volumes->Add Mount volume-> Cloud Storage bucket

- Mount path = /app/assets
- Bucket = browse [You Bucket]
- Allow permission
- Click Save

## create mongoDB atlas

```
https://cloud.mongodb.com/
```

- Create a cluster
- Deploy your cluster => Free, Region
- Click connect->Driver coppy SRV Connection String
- env set MONGODB_URL
- IP Access List->add 0.0.0.0/0
