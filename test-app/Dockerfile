FROM node:10.15.3

LABEL maintainer="Scoop Technologies Inc <ops@takescoop.com>"

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY . ./

CMD ["node", "app/server.js"]

EXPOSE 3000
