#Dockerfile é a criação da image para depois a criação do container
# O AS é uma forma de apelidar os estágios de configurações
#Aqui é o SO do container
FROM node:20 AS base

RUN npm i -g pnpm

FROM base AS dependencies

# definir diretório de trabalho
# se não definido ele irá trabalhar no root do SO
WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml ./

RUN pnpm install

FROM base AS build

WORKDIR /usr/src/app

# esse comando copia tudo por isso os . .
COPY . .
#aqui é necessário copiar a node_modules de dependencies para rodar o projeto
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

RUN pnpm build 
RUN pnpm prune --prod

FROM node:20-alpine3.19 AS deploy

WORKDIR /usr/src/app

RUN npm i -g pnpm prisma

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

RUN pnpm prisma generate

#expoem a porta do projeto
EXPOSE 	3333

#basicamente consegue de fato passar uma instrução a nivel de run de execução
#
CMD [ "pnpm", "start" ]

#container é efemero ele não tem estado por padrão, por default ele é stateless. Se o container parar/deixar de existir 
# todos os dados que não pertencem a imagem base sumirão, oou seja, será usado o volume para armazenar esses dados.
#volume persiste os dados

