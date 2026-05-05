#Op1: Inserimento di una squadra nella base di dati

INSERT INTO `mft`.`squadra` (`nome`, `città`, `stadio`, `anno_fondazione`) VALUES ('', '', '', '');

#Op2: Inserimento di un giocatore nella base di dati

INSERT INTO `mft`.`giocatore` (`cf`, `squadra`, `maglia`, `data_acquisto`, `nome`, `cognome`, `età`, `nazionalità`, `tipo`, `ruolo`) VALUES ('', '', '', '', '', '', '', '', '', '');

#Op3: Inserimento di un contratto nella base di dati

INSERT INTO `mft`.`contratto` (`cf_giocatore`, `data_inizio`, `data_fine`, `ingaggio`, `squadra`) VALUES ('', '', '', '', '');

#Op4: Inserimento di un allenatore nella base di dati

INSERT INTO `mft`.`allenatore` (`codice`, `nome`, `cognome`, `età`) VALUES ('', '', '', '');

#Op5: Inserimento di una competizione nella base di dati

INSERT INTO `mft`.`competizione` (`nome`, `tipo`) VALUES ('', '');

#Op6: Inserimento di un’edizione di una competizione nella base di dati

INSERT INTO `mft`.`edizione_competizione` (`nome_competizione`, `tipo_competizione`, `anno`, `squadra_vincitrice`) VALUES ('', '', '', '');

#Op7: Inserimento di una partita nella base di dati

INSERT INTO `mft`.`partita` (`squadra_casa`, `squadra_ospite`, `data_partita`, `arbitro`, `cartellini_gialli`, `cartellini_rossi`, `risultato`, `nome_competizione`, `tipo_competizione`, `anno_edizione_competizione`, `numero_giornata`) VALUES ('', '', '', '', '', '', '', '', '', '', '');

#Op8: Inserimento della partecipazione di una squadra a una determinata edizione di una competizione 

INSERT INTO `mft`.`partecipazione` (`squadra`, `anno_edizione_competizione`, `nome_competizione`, `tipo_competizione`) VALUES ('', '', '', '');

#Op9: Inserimento di una sostituzione nella base di dati

INSERT INTO `mft`.`sostituzione` (`cf_giocatore1`, `cf_giocatore2`, `minuto`, `squadra`, `squadra_casa`, `squadra_ospite`, `data_partita`) VALUES ('', '', '', '', '', '', '');

#Op10: Inserimento di una gestione corrente da parte di un allenatore nella base di dati

INSERT INTO `mft`.`gestione_corrente` (`allenatore`, `data_inizio`, `squadra`) VALUES ('', '', '');

#Op11: Media degli stipendi dei calciatori di una squadra che partecipa a una determinata edizione di una competizione

SELECT avg(c.ingaggio) stipendio_medio
FROM contratto c
WHERE ((c.squadra = '') and (c.squadra IN (SELECT p.squadra
						  FROM partecipazione p
                                                  WHERE (nome_competizione = '' and 
							 tipo_competizione = '' and
                                                         anno_edizione_competizione = ''))));

#Op12: Numero di tecnici che attualmente allenano una squadra in cui gioca almeno un giocatore di una determinata nazionalità

SELECT count(*) allenatori_calciatori_nazionalità
FROM gestione_corrente gc
WHERE (gc.squadra IN (SELECT g.squadra
		      FROM giocatore g
		      WHERE nazionalità = ''));

#Op13: Nome e cognome dei giocatori titolari che non sono stati sostituiti in nessuna partita

SELECT g.nome nome, g.cognome cognome
FROM giocatore g
WHERE (g.tipo = 'titolare' and NOT EXISTS (SELECT s.cf_giocatore1
					   FROM sostituzione s
					   WHERE g.cf = s.cf_giocatore1));

#Op14: Nome e città delle squadre che hanno stipulato almeno 10 contratti

SELECT s.nome, s.città
FROM squadra s
WHERE (s.nome IN (SELECT c.squadra				  
	          FROM contratto c                  
	          WHERE s.nome = c.squadra                  
	          GROUP BY c.squadra                  
	          HAVING count(*) >= 10));

#Op14(view)

CREATE VIEW squadre_contratti(nome, città, numero) AS
SELECT c.squadra, s.città, count(*)
FROM contratto c JOIN squadra s ON (c.squadra = s.nome)
GROUP BY c.squadra;

SELECT sc.nome, sc.città
FROM squadre_contratti sc
WHERE (sc.numero >= 10);

#Op15: Media degli stipendi dei giocatori di tutte le squadre di una determinata edizione di una competizione

SELECT c.squadra squadra, avg(c.ingaggio) stipendio_medio
FROM contratto c
WHERE ((c.squadra IN (SELECT p.squadra
		      FROM partecipazione p
		      WHERE (nome_competizione = '' and 
			     tipo_competizione = '' and
			     anno_edizione_competizione = ''))))
GROUP BY c.squadra;

#Op16: Codice fiscale del calciatore con stipendio più alto di una determinata squadra

SELECT c.cf_giocatore gioc_max_stip
FROM contratto c
WHERE (c.ingaggio = (SELECT max(c2.ingaggio)
		     FROM contratto c2
                     WHERE c2.squadra = ''));

#Op17: Nome della squadra che ha la spesa più alta in contratti di giocatori

SELECT c.squadra
FROM contratto c
GROUP BY c.squadra
HAVING (sum(c.ingaggio) >= ALL(SELECT sum(c2.ingaggio)
			       FROM contratto c2
                               GROUP BY c2.squadra));
#Op17(view)

CREATE VIEW spese_squadre(nome, spesa) AS
SELECT c.squadra, sum(c.ingaggio)
FROM contratto c
GROUP BY c.squadra;

SELECT sq.nome
FROM spese_squadre sq
WHERE (sq.spesa = ALL(SELECT max(sq2.spesa)
		      FROM spese_squadre sq2));

#Op18: Arbitri che hanno diretto più di 5 partite disputate in un certo stadio

SELECT p.arbitro
FROM partita p
WHERE ((SELECT count(*)	    
        FROM squadra s JOIN partita p ON (s.nome = p.squadra_casa)	    
        WHERE (s.stadio = '')) > 5)
GROUP BY p.arbitro;

#Op18(view)

CREATE VIEW arbitri_stadio(arbitro, partite_dirette) AS
SELECT p.arbitro, count(*)
FROM partita p JOIN squadra s ON (p.squadra_casa = s.nome)
WHERE s.stadio = ''
GROUP BY p.arbitro;

SELECT a.arbitro
FROM arbitri_stadio a
WHERE (partite_dirette > 1);

#Op19: Per ogni squadra trovare il numero di giocatori che sono entrati al posto di un altro in partite di una determinata edizione di una competizione

SELECT s.squadra, count(*) giocatori_entranti
FROM sostituzione s
WHERE ((s.squadra IN (SELECT p.squadra_casa
		      FROM partita p
                      WHERE s.squadra = p.squadra_casa and
			    p.nome_competizione = '' and
                            p.tipo_competizione = '' and
                            p.anno_edizione_competizione = '') or
	  s.squadra IN (SELECT p.squadra_ospite
		        FROM partita p
                        WHERE s.squadra = p.squadra_ospite and
                              p.nome_competizione = '' and
			      p.tipo_competizione = '' and
		              p.anno_edizione_competizione = '')))
GROUP BY s.squadra;

#Op19(view)

CREATE VIEW sostituzioni_squadre(squadra, sostituzioni_tot) AS
SELECT s.squadra, count(*)
FROM sostituzione s JOIN partita p ON (s.squadra_casa = p.squadra_casa and s.data_partita = p.data_partita)
WHERE (p.nome_competizione = '' and p.tipo_competizione = '' and p.anno_edizione_competizione = '')
GROUP BY s.squadra;

SELECT ss.*
FROM sostituzioni_squadre ss;

#Op20: Città con numero di vittorie delle squadre vincitrici di una determinata edizione di una competizione

SELECT s.città, count(*) vittorie
FROM squadra s
WHERE (s.nome IN (SELECT e.squadra_vincitrice
		  FROM edizione_competizione e
                  WHERE (e.nome_competizione = '' and
			 e.tipo_competizione = '')))
GROUP BY s.città;

#Op20(view)

CREATE VIEW vittorie_per_città(città, numero) AS
SELECT s.città, count(*)
FROM squadra s
WHERE (s.nome IN (SELECT e.squadra_vincitrice
		  FROM edizione_competizione e
                  WHERE e.nome_competizione = 'Serie A' and
			e.tipo_competizione = 'nazionale'))
GROUP BY s.città;

SELECT vpc.*
FROM vittorie_per_città vpc;

#Op21: Nazionalità con almeno 4 giocatori che fanno parte della/delle squadra/squadre di una determinata città

SELECT g.nazionalità, count(*) num_giocatori
FROM giocatore g
WHERE (g.squadra IN (SELECT s.nome
		     FROM squadra s
                     WHERE s.città = ''))
GROUP BY g.nazionalità
HAVING num_giocatori >= 4;

#Op21(view)

CREATE VIEW nazionalità_giocatori_città(nazionalità, num_giocatori) AS
SELECT g.nazionalità, count(*)
FROM giocatore g
WHERE (g.squadra IN (SELECT s.nome
		     FROM squadra s
                     WHERE s.città = ''))
GROUP BY g.nazionalità;

SELECT ngc.*
FROM nazionalità_giocatori_città ngc
WHERE ngc.num_giocatori >= 4;

#Op22:  Nome e cognome degli allenatori che hanno effettuato più di 40 cambi in totale nelle partite disputate dalla loro squadra

SELECT a.nome, a.cognome
FROM allenatore a
WHERE (a.codice IN (SELECT gc.allenatore
		    FROM gestione_corrente gc
		    WHERE gc.squadra IN (SELECT s.squadra
					 FROM sostituzione s
                                         WHERE gc.squadra = s.squadra
                                         GROUP BY s.squadra
                                         HAVING count(*) > 40)));

#Op22(view)

CREATE VIEW allenatori_squadre(nome, cognome, squadra) AS
SELECT a.nome, a.cognome, gc.squadra
FROM allenatore a JOIN gestione_corrente gc ON (a.codice = gc.allenatore);

CREATE VIEW cambi_squadre(squadra, num_cambi) AS
SELECT s.squadra, count(*)
FROM sostituzione s
GROUP BY s.squadra;

SELECT a.nome, a.cognome
FROM allenatori_squadre a JOIN cambi_squadre c ON (a.squadra = c.squadra)
WHERE c.num_cambi > 40;