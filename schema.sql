--SCHEMA DATABASE

CREATE DOMAIN intpos AS SMALLINT 
	CHECK (value>=0);

CREATE TYPE grado AS ENUM ('diploma superiore', 'laurea triennale', 'laurea magistrale');
CREATE TYPE impiego AS ENUM ('impiegato', 'segretario', 'direttore');
CREATE TYPE stato_chiamata AS ENUM ('entrata', 'uscita', 'persa');
CREATE TYPE stato_messaggio AS ENUM ('inviato', 'ricevuto');

CREATE TABLE persona
(
    cf character varying(16) PRIMARY KEY,
    nome character varying(25) NOT NULL,
    cognome character varying(25) NOT NULL,
    indirizzo character varying(100) NOT NULL,
    data_nascita date NOT NULL,
);

CREATE TABLE dipendente
(
    id serial NOT NULL UNIQUE,
    cf character varying(16) PRIMARY KEY,
    FOREIGN KEY (cf) REFERENCES persona (cf) 
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);


CREATE TABLE sede
(
    codice character varying(10) PRIMARY KEY,
    indirizzo character varying(100) NOT NULL,
);

CREATE TABLE sim_attiva
(
	codice varchar(20) PRIMARY KEY,
	data_attivazione date NOT NULL DEFAULT CURRENT_DATE,
	data_scadenza date NOT NULL DEFAULT CURRENT_DATE+720,
	numero_telefonico varchar(10) UNIQUE NOT NULL,
	credito numeric(6,2) NOT NULL DEFAULT 0,
	intestatario varchar(16) NOT NULL,
	FOREIGN KEY(intestatario) REFERENCES persona(CF)
);

CREATE TABLE sim_disattivata
(
	codice varchar(20) PRIMARY KEY,
	data_attivazione date NOT NULL,
	data_disattivazione date NOT NULL,
	numero_telefonico varchar(10) NOT NULL,
	intestatario varchar(16) NOT NULL,
	FOREIGN KEY(intestatario) REFERENCES persona(CF)
);

CREATE TABLE conto
(
    iban character varying(27) PRIMARY KEY,
    numero¬_conto character varying(30) NOT NULL UNIQUE,
    banca character varying(40) NOT NULL,
);


CREATE TABLE intestazione
(
    conto character varying(27) NOT NULL,
    intestatario character varying(16) NOT NULL,
    città character varying (20) NOT NULL DEFAULT 'Roma',
    PRIMARY KEY (conto, intestatario),
    FOREIGN KEY (conto) REFERENCES conto (iban),
    FOREIGN KEY (intestatario) REFERENCES persona (cf) 
);

CREATE TABLE ricarica
(
	conto varchar(27) NOT NULL,
	numero varchar(10) NOT NULL,
	data date DEFAULT CURRENT_DATE,
	ora time DEFAULT LOCALTIME,
	importo smallint NOT NULL check (importo >= 5),
	PRIMARY KEY(conto, numero, data, ora),
	FOREIGN KEY(conto) REFERENCES conto(iban),
	FOREIGN KEY(numero) REFERENCES sim_attiva(numero_telefonico)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);




CREATE TABLE tariffa(
	nome varchar(10) PRIMARY KEY,
	minuti intpos DEFAULT 0,
	messaggi intpos DEFAULT 0,
	dati intpos DEFAULT 0,
	prezzo intpos NOT NULL
);


CREATE TABLE offerta_attiva(
	tariffa varchar(10) NOT NULL,
	sim varchar(20) NOT NULL,
	minuti_residui intpos DEFAULT 0,
	messaggi_residui intpos DEFAULT 0,
	dati_residui intpos DEFAULT 0,
	data_attivazione date NOT NULL DEFAULT CURRENT_DATE,
	data_scadenza date NOT NULL DEFAULT CURRENT_DATE+720,
	giorno_rinnovo date NOT NULL DEFAULT CURRENT_DATE+30,
	PRIMARY KEY(tariffa,sim),
	FOREIGN KEY(tariffa) REFERENCES tariffa(nome),
	FOREIGN KEY (sim) REFERENCES sim_attiva(codice)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);



CREATE TABLE offerta_disattivata(
	tariffa varchar(10) NOT NULL,
	sim varchar(20) NOT NULL,
	data_attivazione date NOT NULL,
	data_disattivazione date NOT NULL DEFAULT CURRENT_DATE,
	PRIMARY KEY(tariffa,sim, data_attivazione),
	FOREIGN KEY(tariffa) REFERENCES tariffa(nome),
	FOREIGN KEY (sim) REFERENCES sim_attiva(codice)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);

CREATE TABLE modello(
	nome varchar(40) NOT NULL,
	marca varchar(20) NOT NULL,
	descrizione text,
	PRIMARY KEY(nome)
);


CREATE TABLE telefono_brandizzato(
	codice_prodotto varchar(15) NOT NULL,
	prezzo numeric(6,2),
	modello varchar(40) NOT NULL,
	negozio varchar(10) NOT NULL,
	quantità intpos DEFAULT 0 NOT NULL,
	PRIMARY KEY(negozio,codice_prodotto),
	FOREIGN KEY(negozio) REFERENCES sede(codice),
	FOREIGN KEY(modello) REFERENCES modello(nome)
);

CREATE TABLE titolo(
	codice serial PRIMARY KEY,
	istituto varchar(40) NOT NULL,
	livello grado NOT NULL,
	data date,
	facoltà varchar(40),
	dipendente varchar(16) NOT NULL,
	FOREIGN KEY (dipendente) REFERENCES dipendente(cf)
);

CREATE TABLE occupazione(
	data_inizio date NOT NULL,
	dipendente varchar(16) NOT NULL,
	ruolo impiego,
	stipendio intpos NOT NULL check(stipendio >= 800),
	data_fine date,
	sede varchar(10) NOT NULL,
	PRIMARY KEY(data_inizio, dipendente),
	FOREIGN KEY(dipendente) REFERENCES dipendente(cf),
	FOREIGN KEY(sede) REFERENCES sede(codice)
);

CREATE TABLE traffico_dati(
    	sim varchar(10) NOT NULL,
	data date DEFAULT CURRENT_DATE NOT NULL,
	ora time DEFAULT LOCALTIME NOT NULL,
	durata time,
	dati_utilizzati intpos NOT NULL,
	PRIMARY KEY(sim,data,ora),
	FOREIGN KEY(sim) REFERENCES sim_attiva(numero_telefonico)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);


CREATE TABLE chiamata(
	sim varchar(10) NOT NULL,
	data date DEFAULT CURRENT_DATE NOT NULL,
	ora time DEFAULT LOCALTIME NOT NULL,
	numero_telefonico varchar(10) NOT NULL,
	durata time not null,
	stato stato_chiamata NOT NULL,
	costo numeric(6,2),
	PRIMARY KEY(sim,data,ora, numero_telefonico),
	FOREIGN KEY(sim) REFERENCES sim_attiva(numero_telefonico)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);




CREATE TABLE messaggio(
	sim varchar(10) NOT NULL,
	data date DEFAULT CURRENT_DATE NOT NULL,
	ora time DEFAULT LOCALTIME NOT NULL,
	numero_telefonico varchar(10) NOT NULL,
	stato stato_messaggio NOT NULL,
	costo numeric(6,2),
	PRIMARY KEY(sim, data , ora, numero_telefonico, stato),
	FOREIGN KEY(sim) REFERENCES sim_attiva(numero_telefonico)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
);




 
--FUNZIONI

CREATE OR REPLACE FUNCTION controlla_data(data_inizio date,data_fine date)
RETURNS boolean
LANGUAGE 'plpgsql'
AS $$
declare val boolean;
begin
if(data_fine < data_inizio) Then
		val := false;
	else
		val :=true;
	end if;
return val;
end;
$$;


CREATE OR REPLACE FUNCTION controlla_eta(data_nascita date, anni integer)
RETURNS boolean
LANGUAGE 'plpgsql'
AS $$
declare val boolean;
begin
if(SELECT DATE_PART('day', CURRENT_DATE::timestamp - data_nascita::timestamp)/365.25<anni) Then
		val := false;
	else
		 val :=true;
	end if;
return val;
end;
$$;
 

--TRIGGER


create or replace function eta_persona()
returns trigger as
	$$
	begin
		if not (controlla_eta(new.data_nascita, 12)) then
			RAISE 'età non sufficiente';
		end if;
		return new;
	end;
	$$
	language plpgsql;


create or replace trigger anni_persona
before insert on persona
for each row
EXECUTE function eta_persona();


create or replace function eta_dipendente()
  returns trigger as
	$$
	declare data date;
	begin
		SELECT data_nascita into data
		From persona
		where persona.cf = new.cf;

		if not (controlla_eta(data, 18)) then
			RAISE 'età non sufficiente';
		end if;
		return new;
	end;
	$$
	language plpgsql;

create or replace trigger anni_dipendente
before insert on dipendente
for each row
EXECUTE function eta_dipendente();




create or replace function data_occupazione()
returns trigger as
	$$
	begin
		if not (SELECT new.data_fine is NULL) then
			if (new.data_inizio > new.data_fine) then
				RAISE 'la data di fine deve essere successiva alla data di inizio';
			end if;
		end if;
	return new;
	end;
	$$
	language plpgsql;

create or replace trigger data_occupazione
before insert on occupazione
for each row
EXECUTE function data_occupazione();



CREATE OR REPLACE FUNCTION  data_sim_attiva()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
	begin
		if (new.data_attivazione > new.data_scadenza) then
		      RAISE 'la data di scadenza deve essere successiva alla data attivazione';
		end if;
	return new;
	end;
$$;

create or replace trigger data_sim_attiva
before insert on sim_attiva
for each row
EXECUTE function data_sim_attiva();





CREATE OR REPLACE FUNCTION data_sim_disattivata()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
	
	begin
		if not (controlla_data(new.data_attivazione, new.data_disattivazione)
			and controlla_data(new.data_disattivazione, CURRENT_DATE)) then
			RAISE 'la data di disattivazione deve essere successiva alla data di 
            attivazione e precedente alla data odierna';
		end if;
	return new;
	end;
$$;


create or replace trigger data_sim_disattivata
before insert on sim_disattivata
for each row
EXECUTE function data_sim_disattivata();



CREATE OR REPLACE FUNCTION data_offerta_attiva()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
	
	begin
		if (new.data_attivazione > new.data_scadenza) then
		RAISE 'la data di scadenza deve essere successiva alla data di attivazione';
end if;
	return new;
	end;
$$;

create or replace trigger data_offerta_attiva
before insert on offerta_attiva
for each row
EXECUTE function data_offerta_attiva();




CREATE OR REPLACE FUNCTION data_offerta_disattivata()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
begin
		if not (controlla_data(new.data_attivazione, new.data_disattivazione)
			   and controlla_data(new.data_disattivazione, CURRENT_DATE)) then
			RAISE 'la data di disattivazione deve essere successiva alla data di
attivazione e precedente alla data odierna';
		end if;
	return new;
	end;
$$;


create or replace trigger data_offerta_disattivata
before insert on offerta_disattivata
for each row
EXECUTE function data_offerta_disattivata();





CREATE OR REPLACE FUNCTION controllo_facoltà()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
	begin
	if(new.facoltà is not null and new.livello = 'diploma superiore') then 
		raise 'Il campo facoltà può essere compilato solo in caso di laurea';
	end if;
	return new;
	end;
$$;

create or replace trigger controllo_facoltà
before insert on titolo
for each row
EXECUTE function controllo_facoltà();





CREATE OR REPLACE FUNCTION occupazione_corrente()
RETURNS trigger
LANGUAGE 'plpgsql'
AS $$
	declare numero int;
	begin

	if (new.data_fine is null) then
			Select count(*) into numero
			from occupazione as o
			where (o.dipendente=new.dipendente 
and (o.data_fine is null or o.data_fine > new.data_inizio));

			if(numero > 0) then
				raise 'ogni dipendente può avere una sola occupazione
corrente';
			end if;
	end if;

	if (new.data_fine is not null) then
		Select count(*) into numero
		from occupazione as o
		where (o.dipendente=new.dipendente 
			   and o.data_fine is not null 
			   and((o.data_inizio < new.data_inizio and new.data_inizio < o.data_fine) 
			      or(o.data_inizio < new.data_fine and new.data_fine < o.data_fine)
			      or(new.data_inizio<o.data_inizio and new.data_fine>o.data_fine))
);

		if(numero > 0) then
			raise 'ogni dipendente può avere una sola occupazione corrente';
		end if;
	end if;
	
	if (new.data_fine is not null) then
		Select count(*) into numero
		from occupazione as o
		where (o.dipendente=new.dipendente 
			   and o.data_fine is null and o.data_inizio < new.data_inizio);
	
		if(numero > 0) then
			raise 'ogni dipendente può avere una sola occupazione corrente';
		end if;
	end if;
	return new;
	end;
$$;

create or replace trigger occupazione_corrente
before insert on occupazione
for each row
EXECUTE function occupazione_corrente();




create or replace function ricarica_credito()
returns trigger as
	$$
	begin
		UPDATE sim_attiva
		SET credito = (credito + new.importo)
		WHERE sim_attiva.numero_telefonico=new.numero;
	
	return new;
	end
	$$
	language plpgsql;

create or replace trigger ricarica_credito
after insert on ricarica
for each row
EXECUTE function ricarica_credito();


create or replace function disattivazione_sim()
returns trigger as
	$$
	begin
insert into sim_disattivata(codice,data_attivazione,data_disattivazione,
intestatario,numero_telefonico)
values(old.codice,old.data_attivazione,CURRENT_DATE,old.intestatario,
old.numero_telefonico);
	return new;
	end
	$$
	language plpgsql;

create or replace trigger disattivazione_sim
after delete on sim_attiva
for each row
EXECUTE function disattivazione_sim();





create or replace function disattivazione_offerta()
returns trigger as
	$$
	begin
		insert into offerta_disattivata(data_attivazione, 
data_disattivazione, sim, tariffa)
			values(old.data_attivazione,CURRENT_DATE,old.sim, old.tariffa);
	return new;
	end
	$$
	language plpgsql;

create or replace trigger disattivazione_offerta
after delete on offerta_attiva
for each row
EXECUTE function disattivazione_offerta();


 

create or replace function controllo_messaggi()
returns trigger as
	$$
	declare n INTEGER;
	declare cod varchar;
	declare nome varchar;
	begin
	if(new.stato='inviato')then
		Select count(*) into n
		from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim 
		where offerta_attiva.messaggi_residui > 0 
and sim_attiva.numero_telefonico = new.sim;

		if(n>0)then
			Select min(offerta_attiva.tariffa), sim_attiva.codice into nome,cod
			from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim 
			where offerta_attiva.messaggi_residui > 0 
and sim_attiva.numero_telefonico = new.sim
			group by sim_attiva.codice;
				  
			Update offerta_attiva
			set messaggi_residui = (messaggi_residui-1)
			where nome = offerta_attiva.tariffa and cod = offerta_attiva.sim;  
			new.costo = 0;
		else
			UPDATE sim_attiva
			SET credito = (credito - new.costo)
			WHERE sim_attiva.numero_telefonico=new.sim;
		end if;
	else
		new.costo = 0;
	end if;		 

	return new;
	end
	$$
	language plpgsql;

create or replace trigger controllo_messaggi
before insert on messaggio
for each row
EXECUTE function controllo_messaggi();





 
create or replace function controllo_chiamata()
returns trigger as
$$
declare n INTEGER;
declare cod varchar;
declare nome varchar;
declare m integer;
begin
if(new.stato='uscita')then
	select DATE_PART('m', new.durata) + DATE_PART('h', new.durata)*60 into m;
	Select count(*) into n
	from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim 
	where offerta_attiva.minuti_residui >= m and sim_attiva.numero_telefonico = new.sim;
	
if(n>0)then
			
		Select min(offerta_attiva.tariffa), sim_attiva.codice into nome,cod
		from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim 
		where offerta_attiva.minuti_residui >= m 
and sim_attiva.numero_telefonico = new.sim
		group by sim_attiva.codice;
				  
		Update offerta_attiva
		set minuti_residui = (minuti_residui-m)
		where nome = offerta_attiva.tariffa and cod = offerta_attiva.sim;
new.costo = 0;
	else
		UPDATE sim_attiva
		SET credito = (credito - new.costo)
		WHERE sim_attiva.numero_telefonico=new.sim;

	end if;
else
	new.costo = 0;
end if;
			 

return new;
end
$$
language plpgsql;

create or replace trigger controllo_chiamata
before insert on chiamata
for each row
EXECUTE function controllo_chiamata();





 
create or replace function controllo_dati()
returns trigger as
$$
declare n INTEGER;
declare cod varchar;
declare nome varchar;

begin
	
Select count(*) into n
from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim
where offerta_attiva.dati_residui > new.dati_utilizzati and sim_attiva.numero_telefonico=new.sim;

if(n>0)then
	Select min(offerta_attiva.tariffa), sim_attiva.codice into nome,cod
	from offerta_attiva join sim_attiva on sim_attiva.codice = offerta_attiva.sim 
	where offerta_attiva.dati_residui > new.dati_utilizzati 
and sim_attiva.numero_telefonico = new.sim
	group by sim_attiva.codice;
				  
	Update offerta_attiva
	set dati_residui = (dati_residui- new.dati_utilizzati)
	where nome = offerta_attiva.tariffa and cod = offerta_attiva.sim;
				  
else
	raise 'non è possibile inserire la sessione';

end if;
return new;
end
$$
language plpgsql;

create or replace trigger controllo_dati
before insert on traffico_dati
for each row
EXECUTE function controllo_dati();





--PROCEDURE




create or replace PROCEDURE disattivazione_offerta_b()
	as
	$$
	begin
		delete from offerta_attiva
		where(data_scadenza <= CURRENT_DATE);
	end
	$$
	language plpgsql;







create or replace PROCEDURE disattivazione_sim_b()
	as
	$$
	begin
		delete from sim_attiva
		where(data_scadenza <= CURRENT_DATE);
	end
	$$
	language plpgsql;






create or replace PROCEDURE rinnovo_offerta()
	as
	$$
	declare c numeric(6,2);
	declare p integer;
	declare min integer;
	declare mex integer;
	declare d integer;
	declare o record;
begin
for o in (select * from offerta_attiva where giorno_rinnovo <= CURRENT_DATE)
loop
			select credito into c
			from sim_attiva
			where codice = o.sim;
			
			select prezzo,minuti,messaggi,dati into p, min, mex,d
			from tariffa
			where o.tariffa = tariffa.nome;
			
			if(c>p) then
				UPDATE offerta_attiva
				SET minuti_residui = min, messaggi_residui=mex, 
dati_residui=d, 
giorno_rinnovo=(CURRENT_DATE+30)
				WHERE o.sim = sim and o.tariffa = tariffa;
				
				UPDATE sim_attiva
				SET credito = (c - p)
				WHERE sim_attiva.codice=o.sim;

			else
				UPDATE offerta_attiva
				SET minuti_residui=0,messaggi_residui=0, dati_residui = 0
				WHERE o.sim = sim and o.tariffa = tariffa;
			
			end if;
		end loop;
	end
	$$
	language plpgsql;




