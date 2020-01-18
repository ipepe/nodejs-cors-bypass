FROM node:8.11

COPY . .

RUN npm install

CMD ["node", "server.js"]