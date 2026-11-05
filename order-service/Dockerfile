# Use Node.js base image
FROM node:18-alpine
LABEL org.opencontainers.image.source="https://github.com/usharani-n/microservices-devops"

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and yarn.lock
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install

# Copy the rest of the app's source code
COPY ./ ./

# Expose the port the service will run on
EXPOSE 4000

# Start the service
CMD ["yarn", "start"]
