 -------------------------  Fonctions -----------------------------

CREATE OR REPLACE FUNCTION check_date_archive(p_id_concert INTEGER, p_date_archive DATE) RETURNS BOOLEAN AS $$
    DECLARE
        concert_date DATE;
    BEGIN                                           
        SELECT date_concert INTO concert_date FROM Concert WHERE Concert.id_concert = p_id_concert;
        RETURN p_date_archive > concert_date;
    END;             
$$ LANGUAGE plpgsql;


-- Is_salle_de_concert verifie si un entite est de type salle de concert

CREATE OR REPLACE FUNCTION is_salle_de_concert(id_entite INTEGER) RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (SELECT 1 FROM Entite WHERE Entite.id_entite = $1 AND type = 'Salle de concert');
  END;
$$ LANGUAGE plpgsql;


-- Is_personne verifie si un entite est de type personne

CREATE OR REPLACE FUNCTION is_personne(id_entite INTEGER) RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (SELECT 1 FROM Entite WHERE Entite.id_entite = $1 AND type = 'Personne');
  END;
$$ LANGUAGE plpgsql;

-- Is_groupe verifie si un entite est de type groupe

CREATE OR REPLACE FUNCTION is_groupe(id_entite INTEGER) RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (SELECT 1 FROM Entite WHERE Entite.id_entite = $1 AND type = 'Groupe');
  END;
$$ LANGUAGE plpgsql;
 
-- Is_association verifie si un entite est de type association

CREATE OR REPLACE FUNCTION is_association(id_entite INTEGER) RETURNS BOOLEAN AS $$
  BEGIN
    RETURN EXISTS (SELECT 1 FROM Entite WHERE Entite.id_entite = $1 AND type = 'Association');
  END;
$$ LANGUAGE plpgsql;

--contains verifie si le texte d'un mot cle est contenu dans le texte du commentaire dans lequel il est referencé

CREATE OR REPLACE FUNCTION contains (com_id INTEGER, hashtag_id INTEGER) RETURNS BOOLEAN AS $$
  DECLARE texte_hashtag VARCHAR;
  DECLARE texte_com VARCHAR;  
  BEGIN
    if hashtag_id is NULL then
      RETURN true;
    else
      SELECT hashtag.texte INTO texte_hashtag FROM hashtag WHERE hashtag.id_hashtag = hashtag_id;
      SELECT commentaire.texte INTO texte_com FROM commentaire WHERE commentaire.id_commentaire = com_id;
      RETURN texte_com LIKE '%' || texte_hashtag || '%';
    end if;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE function in_participe(id INTEGER) RETURNS BOOLEAN AS $$
  BEGIN
      RETURN EXISTS (SELECT * FROM participe WHERE id_entite = id);
  END;
$$ LANGUAGE plpgsql;

 ------------------------------ Création des tables ---------------------
DROP TABLE IF EXISTS Entite CASCADE;      --oui
DROP TABLE IF EXISTS Follow CASCADE;--oui
DROP TABLE IF EXISTS Followed_By CASCADE;--oui
DROP TABLE IF EXISTS Concert CASCADE;--oui
DROP TABLE IF EXISTS Concert_Archive CASCADE;--oui
DROP TABLE IF EXISTS participe CASCADE;--oui
DROP TABLE IF EXISTS interesse CASCADE;--oui
DROP TABLE IF EXISTS annonce CASCADE;--oui
DROP TABLE IF EXISTS performe CASCADE;--oui
DROP TABLE IF EXISTS organise CASCADE;--oui
DROP TABLE IF EXISTS avis CASCADE;  --oui
DROP TABLE IF EXISTS commentaire CASCADE; --oui
DROP TABLE IF EXISTS hashtag CASCADE; --oui
DROP TABLE IF EXISTS contient_hashtag CASCADE; --oui
DROP TABLE IF EXISTS tag CASCADE;--oui
DROP TABLE IF EXISTS genre CASCADE;--oui
DROP TABLE IF EXISTS morceau CASCADE;--oui
DROP TABLE IF EXISTS est_de_type CASCADE;--oui
DROP TABLE IF EXISTS playlist CASCADE;--oui
DROP TABLE IF EXISTS tag_playlist CASCADE;--oui
DROP TABLE IF EXISTS est_constitue CASCADE;--oui


 -- Table Entite
CREATE TABLE Entite (
  id_entite SERIAL PRIMARY KEY NOT NULL,
  pseudo VARCHAR(50) NOT NULL,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50) NOT NULL,
  email VARCHAR(50) NOT NULL,
  mot_de_passe VARCHAR(50) NOT NULL,
  type VARCHAR(50) NOT NULL,
  UNIQUE(pseudo),
  UNIQUE(email)
);


-- Table Follow
CREATE TABLE Follow (
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_entite_suivie INTEGER REFERENCES Entite(id_entite) NOT NULL,
  PRIMARY KEY(id_entite, id_entite_suivie),
  CONSTRAINT Check_different CHECK(id_entite <> id_entite_suivie)
);

-- Table Followed_By
CREATE TABLE Followed_By (
  id_entite_suivie INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  PRIMARY KEY(id_entite_suivie, id_entite),
  CONSTRAINT Check_different CHECK(id_entite_suivie <> id_entite)
);

-- Table Concert
CREATE TABLE Concert (
  id_concert SERIAL PRIMARY KEY NOT NULL,
  nom VARCHAR(50) NOT NULL,
  salle INTEGER REFERENCES Entite(id_entite) NOT NULL,
  date_concert DATE NOT NULL,
  heure TIME NOT NULL,
  prix DECIMAL(10,2) NOT NULL,
  genre VARCHAR(50), 
  CONSTRAINT check_salle_concert CHECK (is_salle_de_concert(salle)),
  UNIQUE(salle, date_concert, heure)
);

-- Table Concert_Archive
CREATE TABLE Concert_Archive (
  id_archive SERIAL PRIMARY KEY NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  date_archive DATE NOT NULL,                                                                               
  CONSTRAINT check_archive_date CHECK (check_date_archive(id_concert, date_archive)),
  UNIQUE (id_concert)
);



-- Table participe
CREATE TABLE participe (
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  CONSTRAINT check_participe CHECK (is_personne(id_entite)),
  PRIMARY KEY(id_entite, id_concert)
);

-- Table interesse
CREATE TABLE interesse (
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  CONSTRAINT check_interesse CHECK (is_personne(id_entite) AND NOT(in_participe(id_entite))),
  PRIMARY KEY(id_entite, id_concert)
);

CREATE TABLE annonce (
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  PRIMARY KEY(id_entite, id_concert)
);

CREATE TABLE performe (
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  CONSTRAINT check_type_performe CHECK (is_personne(id_entite) OR is_groupe(id_entite)),
  PRIMARY KEY(id_entite, id_concert)
);

CREATE TABLE organise (
  id_entite INTEGER REFERENCES Entite(id_entite)  NOT NULL,
  id_concert INTEGER REFERENCES Concert(id_concert) NOT NULL,
  CONSTRAINT check_type_organise CHECK (is_association(id_entite) OR is_salle_de_concert(id_entite)),
  PRIMARY KEY(id_entite, id_concert)
);

CREATE TABLE hashtag (
  id_hashtag SERIAL PRIMARY KEY NOT NULL,
  texte VARCHAR(128) NOT NULL,
  UNIQUE(texte)
);

CREATE TABLE commentaire (
  id_commentaire SERIAL PRIMARY KEY NOT NULL,
  texte VARCHAR(2500) NOT NULL
);

CREATE TABLE contient_hashtag (
  id_commentaire INTEGER REFERENCES commentaire(id_commentaire) NOT NULL,
  id_hashtag INTEGER REFERENCES hashtag(id_hashtag) NOT NULL,
  PRIMARY KEY(id_commentaire, id_hashtag),
  CONSTRAINT check_contains CHECK(contains(id_commentaire, id_hashtag))
);

CREATE TABLE avis (
  id_avis SERIAL PRIMARY KEY NOT NULL,
  id_commentaire INTEGER REFERENCES commentaire(id_commentaire) NOT NULL,
  note INTEGER CONSTRAINT check_note CHECK (note >= 1 AND note <= 5),
  type VARCHAR(50)
);

CREATE TABLE tag (
  id_hashtag INTEGER REFERENCES hashtag(id_hashtag) NOT NULL,
  id_entite INTEGER REFERENCES Entite(id_entite) NOT NULL,
  PRIMARY KEY (id_hashtag, id_entite)
);

CREATE TABLE genre (
  id_genre SERIAL PRIMARY KEY NOT NULL,
  nom VARCHAR(50) NOT NULL
);

CREATE TABLE morceau (
  id_morceau SERIAL PRIMARY KEY NOT NULL,
  nom VARCHAR(50) NOT NULL,
  chanteur INTEGER REFERENCES Entite(id_entite) NOT NULL,
  CONSTRAINT check_chanteur CHECK(is_groupe(chanteur))
);

CREATE TABLE est_de_type (
  id_genre INTEGER REFERENCES genre(id_genre) NOT NULL,
  id_morceau INTEGER REFERENCES morceau(id_morceau) NOT NULL,
  PRIMARY KEY(id_genre, id_morceau)
);

CREATE TABLE playlist (
  id_playlist SERIAL PRIMARY KEY NOT NULL,
  createur INTEGER REFERENCES entite(id_entite) NOT NULL
);

CREATE TABLE tag_playlist (
  id_playlist INTEGER REFERENCES playlist(id_playlist) NOT NULL,
  id_hashtag INTEGER REFERENCES hashtag(id_hashtag) NOT NULL,
  PRIMARY KEY (id_playlist, id_hashtag)
);

CREATE TABLE est_constitue (
  id_playlist INTEGER REFERENCES playlist(id_playlist) NOT NULL,
  id_morceau INTEGER REFERENCES morceau(id_morceau) NOT NULL,
  PRIMARY KEY (id_playlist, id_morceau)
);





\copy Entite FROM 'csv/entite.csv' DELIMITER ',' CSV HEADER;
\copy Follow FROM 'csv/follow.csv' DELIMITER ',' CSV HEADER;
\copy Followed_By FROM 'csv/followed_by.csv' DELIMITER ',' CSV HEADER;
\copy Concert FROM 'csv/concert.csv' DELIMITER ',' CSV HEADER;
\copy Concert_Archive FROM 'csv/concert-archive.csv' DELIMITER ',' CSV HEADER;
\copy participe FROM 'csv/participe.csv' DELIMITER ',' CSV HEADER;
\copy interesse FROM 'csv/interesse.csv' DELIMITER ',' CSV HEADER;
\copy annonce FROM 'csv/annonce.csv' DELIMITER ',' CSV HEADER;
\copy performe FROM 'csv/performe.csv' DELIMITER ',' CSV HEADER;
\copy organise FROM 'csv/organise.csv' DELIMITER ',' CSV HEADER;
\copy hashtag FROM 'csv/hashtags.csv' DELIMITER ',' CSV HEADER;
\copy commentaire FROM 'csv/commantaires.csv' DELIMITER ',' CSV HEADER;
\copy avis FROM 'csv/avis.csv' DELIMITER ',' CSV HEADER;
\copy contient_hashtag FROM 'csv/contient_hashtag.csv' DELIMITER ',' CSV HEADER;
\copy tag FROM 'csv/tags.csv' DELIMITER ',' CSV HEADER;
\copy morceau FROM 'csv/morceau.csv' DELIMITER ',' CSV HEADER;
\copy playlist FROM 'csv/playlist.csv' DELIMITER ',' CSV HEADER;
\copy est_constitue FROM 'csv/est_constitue.csv' DELIMITER ',' CSV HEADER;
\copy genre FROM 'csv/genre.csv' DELIMITER ',' CSV HEADER;
\copy est_de_type FROM 'csv/est_de_type.csv' DELIMITER ',' CSV HEADER;
\copy tag_playlist FROM 'csv/tag_playlist.csv' DELIMITER ',' CSV HEADER;