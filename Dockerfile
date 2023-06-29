FROM crystallang/crystal

COPY shard.yml .
COPY shard.override.yml .

RUN shards install

COPY . .

