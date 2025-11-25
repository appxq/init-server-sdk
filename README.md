# InitServerSDK

use for initCraft only

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
SERVICE_NAME = 'API Builder'
SERVICE_VERSION = '1.5.0'
#SERVICE_DESCRIPTION = 'Documentation the InitAPI SDK'
ASSETS_PATH = 'assets/'
HOST = 'localhost'
DOMAIN_URL = "http://localhost:3005"
MONGODB_URL = "mongodb://localhost:27017"
MONGODB_NAME = "dbtest"
MONGODB_USERNAME = "admin"
MONGODB_PASSWORD = "1234"
JWT_SECRET = "werweweffw2234234"
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
