# Deployment components

Source application: github.com/koachcode/ecommerce-server (public, used unchanged).

| Component | Path | Port | Technology | Notes |
|---|---|---|---|---|
| User service | user-service/ | 4002 | Node 18, Express, MongoDB, RabbitMQ | /api/users (register, login) |
| Product service | product-service/ | 4001 | Node 18, Express, MongoDB, RabbitMQ | /api/products; creates the USER-isAuthenticate queue |
| Order service | order-service/ | 4000 | Node 18, Express, MongoDB | /api/orders (auth required) |
| MongoDB | image mongo:6 | 27017 (internal) | - | volume mongo-data |
| RabbitMQ | image rabbitmq:3-management | 5672 (internal) | - | volume rabbitmq-data; user/password from .env |
| Nginx | image nginx:1.27-alpine | 80 (public) | reverse proxy | nginx/default.conf |

Environment variables per service: PORT, NODE_ENV, MONGO_URL, RABBITMQ_URL, JWT_SECRET (user and product), see each service's .env.example. Real values are never committed.

Start order: mongo + rabbitmq healthy -> product-service healthy -> user-service, order-service -> nginx.
Healthchecks use /api-docs/ because the app has no /health endpoint (application code is unchanged).

Image tagging standard: `<service>:<TAG>`, where TAG is the git short SHA or Jenkins build number (set via .env / pipeline). `dev` is used only locally.
