FROM node:8.11

COPY . .

RUN npm install

ENV PORT=80

CMD ["node", "server.js"]