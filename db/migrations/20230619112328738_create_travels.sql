-- +micrate Up
CREATE TABLE travels (
  id SERIAL PRIMARY KEY,
  travel_stops integer[]
);

-- +micrate Down
DROP TABLE travels;
