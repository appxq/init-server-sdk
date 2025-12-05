# InitServerSDK

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

## nodejs install

```
npm i
```

```
npm install pm2 -g
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
PORT = 3005
DOMAIN_URL = "http://localhost:3005"
MONGODB_URL = "mongodb://localhost:27017"
MONGODB_NAME = "dbtest"
MONGODB_USERNAME = "admin"
MONGODB_PASSWORD = "1234"
JWT_SECRET = "_Your_Secret_"
APP_NAME = "Initcraft"
APP_URL = "http://localhost:5173,http://localhost:5174"
APP_MAXSIZE = 100
MAILER_HOST = "smtp.gmail.com"
MAILER_PORT = 465
MAILER_SECURE = "true"
MAILER_USER = "admin@gmail.com"
MAILER_PASSWORD = "123456"
MAILER_FROM = "Admin <admin@gmail.com>"
WS_MAX = 1048576
PUBLIC_KEY = '-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCJUKaPfUKzZtBiKOsKYYGCZCFr
EJEOZ+q/iJBak+bXAN9HVvlL/9u+rNy+HlEtWJAffA2MIXkXV8lzAqeMFmjjee/N
FDOtUsg8r6dqxCMULJpEnZ2ou370CL+XDlxn3oKorwM7LPTe2qr1DTvwVvLJx2hl
tjverk8X5A9+IBcvMQIDAQAB
-----END PUBLIC KEY-----'
REGISTER_ID = '--My License ID--'
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
