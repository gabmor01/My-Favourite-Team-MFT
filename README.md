# Football Club Database

## Project Overview

This project consists in the design and implementation of a relational database for managing the data of a football club and its ecosystem, including players, coach, matches, referees, and competitions.

The system models all the relevant aspects of a football team, such as player contracts and history, coach information, competitions, match details, and player participation in games, along with constraints (e.g. maximum substitutions, match scheduling).

## Methodology

The development of the database followed a structured design process:

- **Conceptual Design**: definition of the main entities (e.g. Player, Coach, Team, Match, Competition, Referee) and their relationships using an ER schema.  
- **Conceptual Schema Refinement**: restructuring of the ER model to remove redundancies and ensure consistency.  
- **Logical Design**: direct translation of the conceptual schema into a relational model.  
- **Relational Schema Refinement**: normalization and optimization of the relational schema.  
- **Physical Design & Implementation**: creation of the database using SQL, including tables, constraints, and relationships.  

## Features

- Management of player personal data, roles, contracts, and transfer history  
- Tracking player availability (injuries and suspensions)  
- Representation of the coach and their career history  
- Management of competitions (national, European, international)  
- Storage of match data, including results, referees, and disciplinary actions  
- Modeling of player participation in matches (starter, substitute, reserve)  
- Enforcement of domain constraints (e.g. maximum 5 substitutions, no multiple matches on the same day)  

## Technologies

- SQL (for database implementation)
