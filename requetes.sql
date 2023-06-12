---1--- jointures multiples ---
---1--- la liste des utilisateurs qui ont participé à un concert dans lequel coldplay a chanté ---

select e.id_entite, e.pseudo
from entite e
join participe p on e.id_entite = p.id_entite
join concert co on p.id_concert = co.id_concert
join performe pe on pe.id_concert = co.id_concert
join entite e1 on e1.id_entite = pe.id_entite
WHERE e1.pseudo = 'coldplay';

---2--- auto jointure ---
---2--- les concerts organisés qui ont vu performer au moins deux entite ---

SELECT Distinct c.nom
FROM performe AS p1
JOIN performe AS p2
ON p1.id_concert = p2.id_concert
JOIN concert AS c 
ON c.id_concert = p1.id_concert
WHERE p1.id_entite <> p2.id_entite;

---3--- sous-requete correlee ---
---3--- les utilisateurs qui sont abonnes a l'association "soundsofjoy" ---

SELECT e.id_entite, e.pseudo
FROM Entite e
WHERE EXISTS (
    SELECT *
    FROM Follow f
    WHERE f.id_entite = e.id_entite
    AND f.id_entite_suivie = (
        SELECT id_entite
        FROM Entite
        WHERE pseudo = 'soundsofjoy'
    )
);

---4--- sous-requete dans le from ---
---4--- l'id, nom et date de tous les concerts qui passent du rock ---

SELECT *
FROM (
    SELECT id_concert, nom, date_concert
    FROM Concert
    WHERE genre = 'Rock'
) AS sous_requete;

---5--- sous-requet dans le where ---
---5--- les personnes qui suivent au moins un groupe

SELECT *
FROM Entite
WHERE id_entite IN (
    SELECT DISTINCT id_entite
    FROM Follow 
    WHERE id_entite_suivie IN (
        SELECT id_entite
        FROM Entite
        WHERE type = 'Groupe'
    )
);

---6--- deux agrégats nécessitant GROUP BY et HAVING
---6--- les concerts dont le prix est inferieur à la moyenne

SELECT id_concert, prix
FROM concert 
WHERE prix < (
    SELECT AVG(prix)
    FROM concert
);

---6--- les hashtags ayant ete utilises au moins 2 fois dans des commentaires

SELECT h.texte, COUNT(h.id_hashtag) AS nb_occurences
FROM hashtag AS h
JOIN contient_hashtag AS c ON c.id_hashtag = h.id_hashtag
GROUP BY h.texte
HAVING COUNT(h.id_hashtag) >= 2;

---7--- une requête impliquant le calcul de deux agrégats ---
---7--- le nombres d'avis et la moyennes des avis de tout les commentaires ---

SELECT id_commentaire, COUNT(*) AS nombre_avis, ROUND(AVG(note)::numeric, 2) AS moyenne_notes
FROM avis
GROUP BY id_commentaire
ORDER BY moyenne_notes DESC;

---7--- les commantaires ayant la plus grande note mais aussi plus grand nombre d'avis ---

WITH moyenne_notes AS (
SELECT id_commentaire, ROUND(AVG(note)::numeric, 2) AS avg_note, COUNT(*) AS nombre_avis
FROM avis
GROUP BY id_commentaire
)
SELECT commentaire.id_commentaire, commentaire.texte, moyenne_notes.avg_note, moyenne_notes.nombre_avis
FROM commentaire
JOIN moyenne_notes ON commentaire.id_commentaire = moyenne_notes.id_commentaire
WHERE (moyenne_notes.avg_note, moyenne_notes.nombre_avis) = (
SELECT MAX(avg_note), MAX(nombre_avis)
FROM moyenne_notes
)
ORDER BY commentaire.id_commentaire;

---8--- une jointure externe
---8--- La liste des salles de concert et les concerts qui y ont lieu (s'il y en a) 

SELECT Entite.id_entite, Entite.nom AS salle_de_concert, Concert.nom AS nom_concert, Concert.date_concert
FROM Entite
LEFT JOIN Concert ON Entite.id_entite = Concert.salle
WHERE Entite.type = 'Salle de concert';

---8--- les noms des concerts et les pseudos des entités qui organisent ces concerts

SELECT Concert.nom, Entite.pseudo
FROM Concert
RIGHT JOIN Organise ON Concert.id_concert = Organise.id_concert
JOIN Entite ON Organise.id_entite = Entite.id_entite;

---8--- les noms des concerts qui n'ont pas été organisé par les entité de noise book
---8--- et les pseudos des entités qui n'ont organisé aucun concerts

SELECT Concert.nom, Entite.pseudo
FROM Concert
FULL JOIN Organise ON Concert.id_concert = Organise.id_concert
FULL JOIN Entite ON Organise.id_entite = Entite.id_entite
WHERE Concert.nom is NULL OR Entite.pseudo is NULL;

---9--- condition de totalité
---9--- les noms des salles de concert qui ne sont associées à aucun concert.

WITH Salles AS (
SELECT *
FROM Entite 
WHERE type = 'Salle de concert'
)
SELECT Salles.nom,Salles.type
FROM Salles
WHERE NOT EXISTS (
  SELECT *
  FROM Concert
  WHERE Concert.salle = Salles.id_entite
);
------
WITH Salles AS (
SELECT *
FROM Entite 
WHERE type = 'Salle de concert'
)
SELECT Salles.nom
FROM Salles
LEFT JOIN Concert ON Concert.salle = Salles.id_entite
GROUP BY Salles.id_entite, Salles.nom
HAVING COUNT(Concert.id_concert) = 0;


---10--- deux requetes qui renvoiraient le meme resultat sans valeurs NULL mais avec des résultats differents en presence de ces valeurs

SELECT Entite.id_entite, Entite.nom, concert.nom
FROM Entite
LEFT JOIN participe ON Entite.id_entite = participe.id_entite
LEFT JOIN concert ON concert.id_concert = participe.id_concert
WHERE Entite.type = 'Personne';

SELECT Entite.id_entite, Entite.nom, concert.nom
FROM Entite
JOIN participe ON Entite.id_entite = participe.id_entite
JOIN concert ON concert.id_concert = participe.id_concert
WHERE Entite.type = 'Personne';

---11--- recursion
---11--- les utilisateurs qui suivent indirectement l'utilisateur "melodiesunited" (id 37)

WITH RECURSIVE follower_chain AS (
  SELECT id_entite, id_entite_suivie
  FROM Follow
  WHERE id_entite_suivie = 37
  
  UNION
  
  SELECT f.id_entite, f.id_entite_suivie
  FROM Follow f
  INNER JOIN follower_chain fc ON f.id_entite_suivie = fc.id_entite
)
SELECT DISTINCT id_entite
FROM follower_chain;

---12--- fenetrage
---12--- les utilisateurs qui ont le plus grand nombre de followers parmi tous les utilisateurs

WITH follower_counts AS (
  SELECT id_entite_suivie, COUNT(*) AS follower_count,
         RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
  FROM Follow
  GROUP BY id_entite_suivie
)
SELECT id_entite_suivie
FROM follower_counts
WHERE rank = 1;
