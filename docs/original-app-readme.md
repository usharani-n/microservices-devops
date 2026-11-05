## Ecommerce Web service

Develop a basic e-commerce site using _**microservices architecture**_. The app should feature services like user management, product catalog, and order processing, and use Docker for containerization.

### Requirements

- Nodejs v18.19.0
- Rabbitmq
- Docker

### Folder structure

```Ecommerce-app-server
├── user-service/ # User management microservice
  ├──src
    ├── controller
    ├── model
    ├── routes
    ├── index.js
  ├── Dockerfile
  ├── swagger.js
  ├── swaggerDoc.js
  ├── .env
  ├── .env.production
├── product-service/ # Product catalog
  ├──src
    ├── controller
    ├── model
    ├── routes
    ├── index.js
  ├── Dockerfile
  ├── swagger.js
  ├── swaggerDoc.js
  ├── .env
  ├── .env.production
├── order-service/ # Order processing microservice
  ├──src
    ├── controller
    ├── model
    ├── routes
    ├── index.js
  ├── Dockerfile
  ├── swagger.js
  ├── swaggerDoc.js
  ├── .env
  ├── .env.production
├── docker-compose.yml # Docker Compose for container management
├── .gitignore
└── README.md
```

### How to start project with one go using docker-compose

#### Run Rabbit MQ

- Download image and run ontainer

```
docker run --hostname my-rabbit --name some-rabbit -p 5672:5672 rabbitmq
```

#### Run Dockr compose

- On root directory run the command below

```cmd
docker-compose up --build

```

#### Service Endpoints Documentation

- [Order Service](/order-service/README.md)
- [User Service](/user-service/README.md)
- [Product Service](/product-service/README.md)
