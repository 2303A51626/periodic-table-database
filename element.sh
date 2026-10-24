#!/bin/bash

if [[ $# -eq 0 ]]; then
  printf 'Please provide an element as an argument.\n'
  exit 0
fi

if ! result=$(psql -X -q -t --no-align -d periodic_table -v ON_ERROR_STOP=1 -v element="$1" 2>/dev/null <<'SQL'
  SELECT e.atomic_number,
         e.name,
         e.symbol,
         t.type,
         p.atomic_mass,
         p.melting_point_celsius,
         p.boiling_point_celsius
  FROM elements AS e
  JOIN properties AS p USING (atomic_number)
  JOIN types AS t USING (type_id)
  WHERE e.atomic_number::text = :'element'
     OR lower(e.symbol) = lower(:'element')
     OR lower(e.name) = lower(:'element')
  LIMIT 1;
SQL
); then
  printf 'Unable to query the periodic_table database.\n' >&2
  exit 1
fi

if [[ -z $result ]]; then
  printf 'I could not find that element in the database.\n'
  exit 0
fi

IFS='|' read -r atomic_number name symbol type atomic_mass melting_point boiling_point <<< "$result"
printf "The element with atomic number %s is %s (%s). It's a %s, with a mass of %s amu. %s has a melting point of %s celsius and a boiling point of %s celsius.\n" \
  "$atomic_number" "$name" "$symbol" "$type" "$atomic_mass" "$name" \
  "$melting_point" "$boiling_point"
