--QUERY

--Op13
--Visualizzazione del ruolo, dello stipendio, dell’iban, del codice fiscale e del titolo dei dipendenti della società 
--che lavorano attualemente per essano e che hanno conseguito una laurea.

select organico.cf, organico.stipendio, organico.ruolo, titolo.livello, titolo.istituto, 
titolo.facoltà, conto.iban,sim_attiva.numero_telefonico
from titolo, conto, sim_attiva,
( 
		--- seleziona i dipendenti attualmente impiegati
select persona.*, dipendente.id, occupazione.*
from dipendente, occupazione, persona
where dipendente.cf = persona.cf 
and persona.cf = occupazione.dipendente
		and occupazione.data_fine IS NULL
) AS organico

where titolo.dipendente=organico.cf
	and titolo.facoltà is not null
	and sim_attiva.intestatario = organico.cf
	and conto.iban in ( 
				--- seleziona gli iban appartenenti al dipendente
 select conto.iban
				from conto, intestazione
				where intestazione.intestatario = organico.cf 
				and intestazione.conto=conto.iban
				);





--Op14:

--Visualizzazione del numero di volte che ogni offerta è stata attivata 
--(si contino come distinti i casi in cui venga attivata più volte sulla medesima sim). 

select tariffa.*, count(*) as numero_attivazioni
from tariffa,

		(
			(
				--- offerte attualmente attive
				select offerta_attiva.tariffa as nome
				from offerta_attiva
			)
	UNION ALL
			(
				--- offerte attualmente disattivate
				select offerta_disattivata.tariffa as nome
				from offerta_disattivata
			)
		) as offerta

where tariffa.nome = offerta.nome
group by tariffa.nome;




--Op15
--Per ogni tariffa si vuole conoscere il numero di sim su cui essa è attiva oppure è stata attiva 
--( se la tariffa è stata attivata più volte su una sim, questa verrà comunque contata una volta).

select tariffa.*, count(*) as numero_sim
from tariffa,

		(
			(
			--- sim su cui è attiva l'offerta
			select distinct offerta_attiva.tariffa as nome, 			
offerta_attiva.sim as sim
			from offerta_attiva
			)
		UNION
			(
			--- sim su cui è stata attiva l'offerta
			select distinct offerta_disattivata.tariffa as nome, 
offerta_disattivata.sim as sim
			from offerta_disattivata
			)
		) as offerta

where tariffa.nome = offerta.nome
group by tariffa.nome;




--Op16 
--Visualizzazione dei movimenti (chiamate, messaggi o ricariche) che sono state effettuati sulla sim con numero telefonico x.
select *
from(
	select sim, data,ora,(-1)*costo, operazione
	from
		(
		--- registro delle chiamate e dei messaggi
			(
				select sim, numero_telefonico, data, ora, costo, 
'M' as operazione
				from messaggio
			)
			UNION ALL
			(
			select sim, numero_telefonico, data, ora, costo, 
'C' as operazione
			from chiamata
) 
		) as registro where costo <> 0
		UNION ALL
		select numero as sim, data,ora,importo as costo, 'R' as operazione
		from ricarica
	) as movimento
where sim = x;




--Op17:
--Per ogni sim si vuole conoscere la media delle uscite (chiamate e messaggi) relativa all’anno in corso.

select sim, -avg(costo)
	from(
			--- registro delle chiamate e dei messaggi nell'ultimo anno
			(
				select sim, numero_telefonico, data, ora, costo, 
'M' as operazione
				from messaggio
			)
			UNION ALL
			(
				select sim, numero_telefonico, data, ora, costo, 
'C' as operazione
				from chiamata
) 
		) as registro 

where costo <> 0 and date_part('year', data)=(SELECT date_part('year', now()))-1
group by sim;





--Op18:
--Visualizzazione dei dati dei dipendenti che percepiscono lo stipendio massimo e possiedono almeno una sim con almeno due offerte attive su di essa
select *
from 
( 
	--- seleziona i dipendenti attualmente impiegati
	select persona.*, dipendente.id, occupazione.*
	from dipendente, occupazione, persona
	where dipendente.cf = persona.cf 
	and persona.cf = occupazione.dipendente
			and occupazione.data_fine IS NULL
	) AS organico

where organico.stipendio = ( --- selezione stipendio più alto
    select max(stipendio)
				    from occupazione
				    where data_fine IS NULL
				  )
	and organico.cf in ( --- selezione cf con almeno una sim con 2 offerte 
select intestatario
				from sim_attiva as s
				where 2 <= (  select count(*)
						from offerta_attiva
						where offerta_attiva.sim = s.codice
								  		)
					  );




--Op19:
--Numero di dipendenti laureati che lavorano per una determinata sede con una media dello stipedio maggiore 1400, 
--che hanno avuto almeno 3 contratti e a cui è intestata una sim attiva e una disattivata

select sede, count(*)
from 
( 
	--- seleziona i dipendenti attualmente impiegati
	select persona.*, dipendente.id, occupazione.*
	from dipendente, occupazione, persona
	where dipendente.cf = persona.cf 
	and persona.cf = occupazione.dipendente
			and occupazione.data_fine IS NULL
	) AS organico
--- selezione degli impiegati con almeno 3 contratti
where 3<= (select count(*)
		from occupazione
		where occupazione.dipendente = organico.cf)
--- selezione dei dipendenti con una laurea
and organico.cf in (select titolo.dipendente
			from titolo
			where titolo.facoltà is not null)
--- selezione dipendenti con almeno una sim attiva
and organico.cf in (select intestatario
			from sim_attiva)

--- selezione dipendenti con almeno una sim disattivata
and organico.cf in (select intestatario
			from sim_disattivata)
group by sede
having avg(stipendio)>1400;




--Op20:
--Visualizzazione dei dati e del numero di telefono delle persone che hanno almeno una sim attiva su cui e attiva almeno una tariffa,
-- su cui sono state effettuate più di 10 ricariche e da ci sono state effettuate almeno 100 chiamatre e 1000 messaggi nell’anno corrente.
select persona.*, sim_attiva.numero_telefonico
from sim_attiva join persona on persona.cf = sim_attiva.intestatario
where codice in (select offerta_attiva.sim
			from offerta_attiva
			where offerta_attiva.sim = codice)
	--- seleziona sim sui sono state effettuate almeno 10 ricariche nell’anno
and 10<= (select count (*)
		from ricarica
		where ricarica.numero = numero_telefonico
		and date_part('year', data)=(SELECT date_part('year', now()))-1)
	--- seleziona sim che hanno  effettuato almeno 100 chiamate nell’anno
and 1<= (select count (*)
		from chiamata
		where chiamata.sim = sim_attiva.numero_telefonico
		and chiamata.stato ='uscita'
		and date_part('year', data)=(SELECT date_part('year', now()))-1)
	
	--- seleziona sim che hanno  effettuato almeno 1000 messaggi nell’anno
and 1<= (select count (*)
		from messaggio
		where messaggio.sim = sim_attiva.numero_telefonico
		and messaggio.stato='inviato'
		and date_part('year', data)=(SELECT date_part('year', now()))-1);




--Op21:
--Per ogni sim vengono selezionati i dati del proprietario e della chiamata più duratura che è stata effettuata dalla sim.

select persona.*,chiamata.*
from persona, sim_attiva, chiamata
where persona.cf = sim_attiva.intestatario
	and chiamata.sim = sim_attiva.numero_telefonico
	and durata >= ALL(select durata
				from chiamata
				where sim_attiva.numero_telefonico = chiamata.sim); 




--QUERY RISCRITTE CON VISTE



--Op13:
--Visualizzazione del ruolo, dello stipendio, dell’iban, del codice fiscale e del titolo dei dipendenti della società 
--che lavorano attualemente per essano e che hanno conseguito una laurea.

--- dipendenti attualmente impegati nell’azienda
create view organico as( 
select persona.*, dipendente.id, occupazione.*
from dipendente, occupazione, persona
where dipendente.cf = persona.cf 
and persona.cf = occupazione.dipendente
		and occupazione.data_fine IS NULL
);

select organico.cf, organico.stipendio, organico.ruolo, titolo.livello, titolo.istituto, 
titolo.facoltà, conto.iban,sim_attiva.numero_telefonico
from titolo, conto, sim_attiva, organico
where titolo.dipendente=organico.cf
	and titolo.facoltà is not null
	and sim_attiva.intestatario = organico.cf
	and conto.iban in ( 
				--- seleziona gli iban appartenenti al dipendente
 select conto.iban
				from conto, intestazione
				where intestazione.intestatario = organico.cf 
				and intestazione.conto=conto.iban
				);




--Op16 
--Visualizzazione dei movimenti (chiamate, messaggi o ricariche) che sono state effettuati sulla sim con numero telefonico x.

--- registro delle chiamate e dei messaggi
create view registro as
(
(
	select sim, numero_telefonico, data, ora, costo, 'M' as operazione
	from messaggio
)
	UNION ALL
	(
	select sim, numero_telefonico, data, ora, costo, 'C' as operazione
	from chiamata
	)
);

create view movimenti as(
		select sim, data,ora,(-1)*costo, operazione
		from registro	
	UNION ALL
		select numero as sim, data,ora,importo as costo, 'R' as operazione
		from ricarica
	);


select *
from movimenti
where sim = x and  costo <> 0;




--Op18:
--Visualizzazione dei dati dei dipendenti che percepiscono lo stipendio massimo e possiedono almeno una sim con almeno due offerte attive su di essa

---con riferimento alla vista organico definita in Op13

select *
from organico
where organico.stipendio = ( --- selezione stipendio più alto
    select max(stipendio)
				    from occupazione
				    where data_fine IS NULL
				  )

	and organico.cf in ( --- selezione cf con almeno una sim con 2 offerte 
select intestatario
				from sim_attiva as s
				where 2 <= (  select count(*)
						from offerta_attiva
						where offerta_attiva.sim = s.codice
								  		)
					  );



--Op17:
--Per ogni sim si vuole conoscere la media delle uscite (chiamate e messaggi) relativa all’anno in corso.

--- con riferiemnto alla vista registro definita nella Op16
select sim, -avg(costo)
from registro
where costo <> 0 and date_part('year', data)=(SELECT date_part('year', now()))-1
group by sim;





--Op19:
--Numero di dipendenti laureati che lavorano per una determinata sede con una media dello stipedio maggiore 1400, 
--che hanno avuto almeno 3 contratti e a cui è intestata una sim attiva e una disattivata

---con riferimento alla vista organico definita in Op13

--- lista dei codici fiscali dei dipendenti che possiedono una laurea
create view laureati as(
select titolo.dipendente 
				from titolo
				where titolo.facoltà is not null
			   );



select sede, count(distinct(cf))
from organico join laureati on lareati.dipendente = organico.cf
--- selezione degli impiegati con almeno 3 contratti
where 3<= (select count(*)
		from occupazione
		where occupazione.dipendente = organico.cf)
--- selezione dipendenti con almeno una sim attiva
and organico.cf in (select intestatario
			from sim_attiva)
--- selezione dipendenti con almeno una sim disattivata
and organico.cf in (select intestatario
			from sim_disattivata)
group by sede
having avg(stipendio)>1400;



