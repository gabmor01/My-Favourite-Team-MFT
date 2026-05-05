create database mft;
use mft;
create table squadra(nome varchar(50) primary key, città varchar(50) not null, stadio varchar(50) not null, 
					 anno_fondazione integer not null);
create table sede(squadra varchar(50), via varchar(50), civico integer, cap integer,
				  foreign key (squadra) references squadra(nome),
				  primary key(squadra, via, civico, cap));
create table giocatore(cf varchar(20) primary key, squadra varchar(50) not null, maglia integer not null, 
					   data_acquisto date not null, nome varchar(50) not null, cognome varchar(50) not null, 
					   età integer not null, ruolo enum('portiere', 'difensore', 'centrocampista', 'attaccante') not null, 
					   nazionalità varchar(50) not null, tipo enum('titolare', 'panchinaro', 'riserva') not null,
					   foreign key (squadra) references squadra(nome));
create table contratto(cf_giocatore varchar(20), data_inizio date, data_fine date not null, 
					   ingaggio int not null, squadra varchar(50) not null,
					   foreign key (cf_giocatore) references giocatore(cf),
					   foreign key (squadra) references squadra(nome),
					   primary key(cf_giocatore, data_inizio));
create table composizione_passata(squadra varchar(50), cf_giocatore varchar(20), data_acquisto date, 
						       data_cessione date not null,
                               foreign key (squadra) references contratto(squadra),
						       foreign key (cf_giocatore) references contratto(cf_giocatore),
						       primary key(squadra, cf_giocatore, data_acquisto));
create table infortunato(cf_giocatore varchar(20), tipo_infortunio varchar(50), tempo_recupero int,
						 foreign key (cf_giocatore) references giocatore(cf),
						 primary key(cf_giocatore, tipo_infortunio, tempo_recupero));
create table squalificato(cf_giocatore varchar(20), data_squalifica date, numero_partite int,
						  foreign key (cf_giocatore) references giocatore(cf),
						  primary key(cf_giocatore, data_squalifica, numero_partite));
create table competizione(nome varchar(50), tipo enum('mondiale', 'europea', 'nazionale'),
						  primary key(nome, tipo));
create table edizione_competizione(nome_competizione varchar(50), 
								   tipo_competizione enum('mondiale', 'europea', 'nazionale'),
								   anno int, squadra_vincitrice varchar(50) default null,
								   foreign key (nome_competizione, tipo_competizione) references competizione(nome, tipo),
								   foreign key (squadra_vincitrice) references squadra(nome),
								   primary key(nome_competizione, tipo_competizione, anno));
create table partecipazione(squadra varchar(50), anno_edizione_competizione int, nome_competizione varchar(50),
							tipo_competizione enum('mondiale', 'europea', 'nazionale'),
							foreign key (squadra) references squadra(nome),
							foreign key (nome_competizione, tipo_competizione, anno_edizione_competizione) references edizione_competizione(nome_competizione, tipo_competizione, anno),
							primary key(squadra, anno_edizione_competizione, nome_competizione, tipo_competizione));
create table partita(squadra_casa varchar(50), squadra_ospite varchar(50) not null, data_partita date, 
			arbitro varchar(20) not null, cartellini_gialli int not null check(cartellini_gialli <= 64), 
            cartellini_rossi int not null check(cartellini_rossi <= 32), risultato varchar(20) not null,
		    nome_competizione varchar(50) not null, tipo_competizione enum('mondiale', 'europea', 'nazionale'),
		    anno_edizione_competizione int not null, 
            numero_giornata int not null check(numero_giornata > 0 and numero_giornata < 39),
		    foreign key (squadra_casa) references squadra(nome),
		    foreign key (squadra_ospite) references squadra(nome),
            foreign key (nome_competizione, tipo_competizione, anno_edizione_competizione) 
            references partecipazione(nome_competizione, tipo_competizione, anno_edizione_competizione),
		    primary key(squadra_casa, data_partita));
create table sostituzione(cf_giocatore1 varchar(20), cf_giocatore2 varchar(20) references giocatore(cf), 
			  minuto int check(minuto > 0 and minuto <= 90), squadra varchar(50) not null,
			  squadra_casa varchar(50) not null, squadra_ospite varchar(50) not null references squadra(nome), 
              data_partita date,
			  foreign key (cf_giocatore1) references giocatore(cf),
              foreign key (squadra) references squadra(nome),
			  foreign key (squadra_casa, data_partita) references partita(squadra_casa, data_partita),
			  primary key(cf_giocatore1, cf_giocatore2, data_partita));
create table allenatore(codice varchar(20) primary key, nome varchar(50) not null, cognome varchar(50) not null, 
						età int not null);
create table gestione_corrente(allenatore varchar(20), data_inizio date, squadra varchar(50) not null,
							   foreign key (allenatore) references allenatore(codice),
							   foreign key (squadra) references squadra(nome),
							   primary key (allenatore, data_inizio));
create table gestione_passata(allenatore varchar(20), data_inizio date, data_fine date, squadra varchar(50) not null,
							  foreign key (allenatore) references allenatore(codice),
							  foreign key (squadra) references squadra(nome),
							  primary key (allenatore, data_inizio, data_fine));
DELIMITER |
CREATE TRIGGER mft.date_giocatore
BEFORE INSERT ON composizione_passata
FOR EACH ROW
BEGIN
	IF (new.data_acquisto > new.data_cessione) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT= 'Errore: data_acquisto > data_cessione';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.date_contratto
BEFORE INSERT ON contratto
FOR EACH ROW
BEGIN
	IF (new.data_inizio > new.data_fine) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT= 'Errore: data_inizio contratto > data_fine contratto';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.date_gestione
BEFORE INSERT ON gestione_passata
FOR EACH ROW
BEGIN
	IF (new.data_inizio > new.data_fine) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT= 'Errore: data_inizio gestione > data_fine gestione';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.stessa_squadra
BEFORE INSERT ON partita
FOR EACH ROW
BEGIN
	IF (new.squadra_casa = new.squadra_ospite) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT='Errore: squadra contro se stessa';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.squadra_partecipante
BEFORE INSERT ON partita
FOR EACH ROW
BEGIN
	DECLARE sqc_part_comp varchar(50);
    DECLARE sqo_part_comp varchar(50);

	SET sqc_part_comp = (SELECT partecipazione.squadra
			    FROM partecipazione
			    WHERE (new.squadra_casa = partecipazione.squadra and
					   new.anno_edizione_competizione = partecipazione.anno_edizione_competizione and
					   new.nome_competizione = partecipazione.nome_competizione and 
				       new.tipo_competizione = partecipazione.tipo_competizione)
					  );
	SET sqo_part_comp = (SELECT partecipazione.squadra
			    FROM partecipazione
			    WHERE (new.squadra_ospite = partecipazione.squadra and
					   new.anno_edizione_competizione = partecipazione.anno_edizione_competizione and
					   new.nome_competizione = partecipazione.nome_competizione and 
				       new.tipo_competizione = partecipazione.tipo_competizione)
					  );
                      
	IF (sqc_part_comp IS NULL or sqo_part_comp IS NULL) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT='Errore: la/le squadra/e non partecipano alla competizione';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.anno_partita
BEFORE INSERT ON partita
FOR EACH ROW
BEGIN
	IF (year(new.data_partita) <> new.anno_edizione_competizione) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: la data della partita non corrisponde con edizione della competizione';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.limite_sostituzioni_casa
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE count_sost int;

	SET count_sost = (SELECT count(*)
					  FROM sostituzione JOIN partita ON (sostituzione.squadra_casa = partita.squadra_casa and
														 sostituzione.data_partita = partita.data_partita)
					  WHERE new.squadra = new.squadra_casa and ((new.squadra_casa, new.data_partita) =
																(partita.squadra_casa, partita.data_partita))
                      GROUP BY sostituzione.squadra
                      HAVING (new.squadra = sostituzione.squadra)
                      );
	IF (count_sost >= 5) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: sostituzioni terminate';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.limite_sostituzioni_ospite
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE count_sost int;

	SET count_sost = (SELECT count(*)
					  FROM sostituzione JOIN partita ON (sostituzione.squadra_casa = partita.squadra_casa and
														 sostituzione.data_partita = partita.data_partita)
					  WHERE new.squadra = new.squadra_ospite and ((new.squadra_ospite, new.data_partita) =
																(partita.squadra_ospite, partita.data_partita))
                      GROUP BY sostituzione.squadra
                      HAVING new.squadra = sostituzione.squadra);
	IF (count_sost >= 5) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: sostituzioni terminate';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.sostituzione_squadra
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	IF (new.squadra <> new.squadra_casa and new.squadra <> new.squadra_ospite) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: la squadra che effettua la sostituzione non sta disputando la partita';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.sostituzione_squadra_giocatori
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE sq1 varchar(50);
	DECLARE sq2 varchar(50);

	SET sq1 = (SELECT giocatore.squadra
		   FROM giocatore
           WHERE new.cf_giocatore1 = giocatore.cf);
	SET sq2 = (SELECT giocatore.squadra
		   FROM giocatore
           WHERE new.cf_giocatore2 = giocatore.cf);

	IF (sq1 <> new.squadra or sq2 <> new.squadra) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: il/i giocatore/i sostituiti non appartiene/appartengono al club che effettua la sostituzione';
	END IF;
END
|

DELIMITER |
CREATE TRIGGER mft.giocatori_titolari
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE gioc_tit varchar(20);
	
	SET gioc_tit = (SELECT giocatore.cf 
			FROM giocatore
			WHERE tipo = 'titolare' and new.cf_giocatore1 = giocatore.cf);
	IF (gioc_tit IS NULL) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: Il giocatore non si trova in campo quindi non può essere sostituito';
	END IF;
END;
|

DELIMITER |
CREATE TRIGGER mft.giocatori_panchinari
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE gioc_pan varchar(20);
	
	SET gioc_pan = (SELECT giocatore.cf 
			FROM giocatore
			WHERE tipo = 'panchinaro' and new.cf_giocatore2 = giocatore.cf);
	IF (gioc_pan IS NULL) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: Il giocatore non si trova in panchina quindi non può entrare in campo';
	END IF;
END;
|

DELIMITER |
CREATE TRIGGER mft.ruolo_giocatori_sostituzione
BEFORE INSERT ON sostituzione
FOR EACH ROW
BEGIN
	DECLARE ruolo1 enum('portiere', 'difensore', 'centrocampista', 'attaccante');
    DECLARE ruolo2 enum('portiere', 'difensore', 'centrocampista', 'attaccante');
	
	SET ruolo1 = (SELECT giocatore.ruolo 
				  FROM giocatore
				  WHERE new.cf_giocatore1 = giocatore.cf);
	SET ruolo2 = (SELECT giocatore.ruolo 
				  FROM giocatore
				  WHERE new.cf_giocatore2 = giocatore.cf);
	IF (ruolo1 <> ruolo2) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: I giocatori non giocano nello stesso ruolo';
	END IF;
END;
|

DELIMITER |
CREATE TRIGGER mft.partecipazione_squadra
BEFORE UPDATE ON edizione_competizione
FOR EACH ROW
BEGIN

	IF NOT EXISTS (SELECT partecipazione.squadra
		       FROM partecipazione
		       WHERE new.squadra_vincitrice = partecipazione.squadra and 
                             new.nome_competizione = partecipazione.nome_competizione and
			     new.tipo_competizione = partecipazione.tipo_competizione and
                             new.anno = partecipazione.anno_edizione_competizione) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: La squadra non ha partecipato alla competizione';
	END IF;
END;
|

DELIMITER |
CREATE TRIGGER mft.partecipazione_sq
BEFORE INSERT ON edizione_competizione
FOR EACH ROW
BEGIN

	IF new.squadra_vincitrice IS NOT NULL and NOT EXISTS (SELECT partecipazione.squadra
				   FROM partecipazione
				   WHERE new.squadra_vincitrice = partecipazione.squadra and 
						 new.nome_competizione = partecipazione.nome_competizione and 
                         new.tipo_competizione = partecipazione.tipo_competizione and
                         new.anno = partecipazione.anno_edizione_competizione) THEN
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Errore: La squadra non ha partecipato alla competizione';
	END IF;
END;
|