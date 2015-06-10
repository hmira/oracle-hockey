
--struktury

--1 pomocna 1
create table valid_pozicia(
	pozicia_id number primary key,
	pozicia_nazov varchar2(20)
);

insert into valid_pozicia values(0, 'N/A');
insert into valid_pozicia values(1, 'center');
insert into valid_pozicia values(2, 'lave kridlo');
insert into valid_pozicia values(3, 'prave kridlo');
insert into valid_pozicia values(4, 'obrana');
insert into valid_pozicia values(5, 'brankar');

--1
create table hokejista(
	id number not null,
	meno varchar2(10) not null,
	priezvisko varchar2(10) not null,
	cislo number,
	datum_narodenia date not null,
	pozicia number references valid_pozicia( pozicia_id ) not null,

	constraint PK_hokejista_id primary key (id)
);

--2
create table tim(
	id number not null,
	nazov varchar2(30) not null,
	GPS varchar2(30) not null,

	constraint PK_tim_id primary key (id)
);

--3 pomocna 1
create table valid_typ_zapasu(
	typ_zapasu_id number primary key,
	typ_zapasu_nazov varchar2(10)
);

insert into valid_typ_zapasu values(1, 'skupina');
insert into valid_typ_zapasu values(2, 'playoff');
insert into valid_typ_zapasu values(3, 'exhibicia');

--3 pomocna 2
create table valid_ukoncenie_zapasu(
  ukoncenie_zapasu_id number primary key,
  ukoncenie_zapasu_nazov varchar2(10)
);
insert into valid_ukoncenie_zapasu values(1, 'standard');
insert into valid_ukoncenie_zapasu values(2, 'predlzenie');
insert into valid_ukoncenie_zapasu values(3, 'najazdy');

--3
create table zapas(
	id number not null,
	mesto varchar2(10) not null,
	cas timestamp not null,
	tim_doma number not null,
	tim_vonku number not null,
	goly_domaci number not null,
	goly_vonku number not null,
	typ_zapasu number references valid_typ_zapasu( typ_zapasu_id ) not null,
	ukoncenie_zapasu number references valid_ukoncenie_zapasu( ukoncenie_zapasu_id ) not null,

	constraint PK_zapas_id primary key (id),
	constraint FK_zapas_tim_doma foreign key (tim_doma) references tim(id),
	constraint FK_zapas_tim_vonku foreign key (tim_vonku) references tim(id)
);


--4
create table gol(
	zapas number not null,
	hokejista number not null,
	cas number not null,
	asistencia1 number,
	asistencia2 number,

	constraint PK_gol_id primary key (zapas, hokejista, cas),
	constraint FK_gol_hokejista foreign key (hokejista) references hokejista(id),
	constraint FK_gol_asistencia1 foreign key (asistencia1) references hokejista(id),
	constraint FK_gol_asistencia2 foreign key (asistencia2) references hokejista(id),
	constraint FK_gol_zapas foreign key (zapas) references zapas(id)
);

--5 pomocna + definicia
create table valid_uspesnost_strely(
	uspesnost_strely_id number primary key,
	uspesnost_strely_nazov varchar2(10)
);
insert into valid_uspesnost_strely values(1, 'gol');
insert into valid_uspesnost_strely values(2, 'hit');
insert into valid_uspesnost_strely values(3, 'miss');

--5
create table strela_na_branu(
	id number not null,
	strelec number not null,
	brankar number,
	zapas number not null,
	uspesnost_strely number references valid_uspesnost_strely( uspesnost_strely_id ) not null,

	constraint PK_strela_na_branu_id primary key (id),
	constraint FK_strela_na_branu_strelec foreign key (strelec) references hokejista (id),
	constraint FK_strela_na_branu_brankar foreign key (brankar) references hokejista (id),
	constraint FK_strela_na_branu_zapas foreign key (zapas) references zapas (id)
);

--6
create table vylucenie(
	zapas number not null,
	tim number not null,
	hokejista number not null,
	cas number not null,
	dlzka number not null,

	constraint PK_vylucenie_id primary key (zapas, hokejista, cas),
	constraint FK_vylucenie_tim foreign key (tim) references tim(id),
	constraint FK_vylucenie_zapas foreign key (zapas) references zapas(id),
	constraint FK_vylucenie_hokejista foreign key (hokejista) references hokejista(id)
);

--7
create table kontrakt(
	id number not null,
	hokejista number not null,
	tim number not null,
	od date not null,
	do date not null,
	suma number not null,

	constraint PK_kontrakt_id primary key (id),
	constraint FK_kontrakt_hokejista foreign key (hokejista) references hokejista(id),
	constraint FK_kontrakt_tim foreign key (tim) references tim(id)
);

-----------------------------------------------------------------------------
--triger miesto auto-incrementu
-----------------------------------------------------------------------------

create sequence S_hokejista_id; --1
create or replace trigger T_hokejista_id
	before insert
	on hokejista FOR EACH ROW
	begin
		select S_hokejista_id.nextval into :new.id from dual;
	end;
/

create sequence S_tim_id; --2
create or replace trigger T_tim_id
	before insert
	on tim FOR EACH ROW
	begin
		select S_tim_id.nextval into :new.id from dual;
	end;
/

create sequence S_zapas_id; --3
create or replace trigger T_zapas_id
	before insert
	on zapas FOR EACH ROW
	begin
		select S_zapas_id.nextval into :new.id from dual;
	end;
/

create sequence S_strela_na_branu_id; --5
create or replace trigger T_strela_na_branu_id
	before insert
	on strela_na_branu FOR EACH ROW
	begin
		select S_strela_na_branu_id.nextval into :new.id from dual;
	end;
/

create sequence S_kontrakt_id; --7
create or replace trigger T_kontrakt_id
	before insert
	on kontrakt FOR EACH ROW
	begin
		select S_kontrakt_id.nextval into :new.id from dual;
	end;
/


-----------------------------------------------------------------------------
--triger zajistujuci integritu dat
-----------------------------------------------------------------------------
create or replace trigger T_bef_ins_row_kontrakt
  before insert or update
  on kontrakt FOR EACH ROW
  declare
    xpocet number;
    xcislo number;
  begin
	  select count(*) into xpocet
	  from kontrakt
	  where (hokejista = :new.hokejista)
	  and ((do > :new.od)
	  or (od < :new.do));

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20067, 'Hrac uz kontrakt v tomto obdobi ma');
		  end;
	  end if;

	  select cislo into xcislo
	  from hokejista
	  where id = :new.hokejista;

	  select count(*) into xpocet
	  from kontrakt k
	  inner join hokejista h on k.hokejista = h.id 
	  where (h.cislo = xcislo)
	  and (k.tim = :new.tim)
	  and ((k.do > :new.od)
	  or (k.od < :new.do));

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20067, 'Hrac s cislom pre toto obdobie uz existuje');
		  end;
	  end if;

  end;
/

--aby nemohol mat bez kontraktu strelu
create or replace trigger T_bef_ins_row_strela
  before insert or update
  on strela_na_branu FOR EACH ROW
  declare
    xpocet number;
    xpozicia_brankar varchar2(10);
  begin
	  select count(*) into xpocet
	  from kontrakt k
	  inner join hokejista h on h.id = k.hokejista
	  cross join zapas z 
	  where (hokejista = :new.strelec)
	  and z.cas > to_timestamp(k.od)
	  and z.cas < to_timestamp(k.do)
	  and (z.id = :new.zapas);

	  select pozicia_nazov into xpozicia_brankar
	  from hokejista h
	  join valid_pozicia vp on h.pozicia = vp.pozicia_id
	  where pozicia_id = :new.brankar;

	  if xpocet = 0 then
		  begin
		  	raise_application_error(-20068, 'Hrac nema kontrakt, nemoze zaznamenat statistiku (strela)');
		  end;
	  end if;

	  if (xpozicia_brankar <> 'brankar') then
	  	begin
	  		raise_application_error(-20069, 'Strela moze byt len na brankara');
      	end;
	  end if;
    
	  if (:new.strelec = :new.brankar) then
	  	begin
	  		raise_application_error(-20069, 'Brankar nemoze vystrelit sam na seba');
      	end;
	  end if;
  end;
/

--aby nemohol mat bez kontraktu gol
create or replace trigger T_bef_ins_row_gol
  before insert or update
  on gol FOR EACH ROW
  declare
    xpocet number;
  begin
  	  select count(*) into xpocet
	  from kontrakt k
	  inner join hokejista h on h.id = k.hokejista
	  cross join zapas z 
	  where (hokejista = :new.hokejista)
	  and z.cas > to_timestamp(k.od)
	  and z.cas < to_timestamp(k.do)
	  and (z.id = :new.zapas);

	  if xpocet = 0 then
		  begin
		  	raise_application_error(-20068, 'Hrac nema kontrakt, nemoze vstrelit gol');
		  end;
	  end if;

  	  select count(*) into xpocet
	  from vylucenie v
	  where (v.hokejista = :new.hokejista)
	  and v.cas + v.dlzka < :new.cas
	  and (v.zapas = :new.zapas);

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20068, 'Hracovi sa cas golu prekryva s vylucenim');
		  end;
	  end if;
  end;
/

--aby nemohol mat bez kontraktu gol
create or replace trigger T_bef_ins_row_vylucenie
  before insert or update
  on vylucenie FOR EACH ROW
  declare
    xpocet number;
  begin
  	  select count(*) into xpocet
	  from kontrakt k
	  inner join hokejista h on h.id = k.hokejista
	  cross join zapas z 
	  where (hokejista = :new.hokejista)
	  and z.cas > to_timestamp(k.od)
	  and z.cas < to_timestamp(k.do)
	  and (z.id = :new.zapas);

	  if xpocet = 0 then
		  begin
		  	raise_application_error(-20068, 'Hrac nema kontrakt, nemoze zaznamenat statistiku (vylucenie)');
		  end;
	  end if;

  	  select count(*) into xpocet
	  from vylucenie v
	  where (v.hokejista = :new.hokejista)
	  and v.cas + v.dlzka < :new.cas
	  and (v.zapas = :new.zapas);

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20068, 'Hracovi sa vylucenie prekryva');
		  end;
	  end if;
  end;
/

--aby nemohol mat bez kontraktu gol
create or replace trigger T_bef_ins_row_zapas
  before insert or update
  on zapas FOR EACH ROW
  declare
    xpocet number;
  begin
  	  select count(*) into xpocet
	  from zapas z
	  where :new.cas > z.cas - INTERVAL '3' HOUR
	  and :new.cas < z.cas + INTERVAL '3' HOUR
	  and (:new.tim_doma = z.tim_doma or :new.tim_vonku = z.tim_doma or :new.tim_doma = z.tim_vonku or :new.tim_vonku = z.tim_vonku);

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20068, 'Kazde muzstvo musi mat od zaciatkov dvoch zapasov odstup minimalne 3 hodiny');
		  end;
	  end if;

	  select count(*) into xpocet
	  from zapas z
	  where :new.cas > z.cas - INTERVAL '3' HOUR
	  and :new.cas < z.cas + INTERVAL '3' HOUR
	  and z.mesto = z.mesto;

	  if xpocet <> 0 then
		  begin
		  	raise_application_error(-20068, 'Cas vyhradeny na mieste na zapas musi byt minimalne 3 hodiny');
		  end;
	  end if;

	  if :new.tim_doma = :new.tim_vonku then
		  begin
		  	raise_application_error(-20069, 'Nemoze hrat muzstvo same so sebou');
		  end;
	  end if;
  end;
/

--procedury
create or replace package zapas_db as

	procedure pridaj(
		xmesto zapas.mesto%type,
		xcas varchar2, --'1. 9. 2012 17:12:00'
		xdoma zapas.tim_doma%type,
		xvonku zapas.tim_vonku%type,
		xgoly_domaci zapas.goly_domaci%type default null,
		xgoly_vonku zapas.goly_vonku%type default null,
		xtyp zapas.typ_zapasu%type default null,
		xukoncenie zapas.ukoncenie_zapasu%type default null
		);
end;
/

create or replace package body zapas_db as

	procedure pridaj(
		xmesto zapas.mesto%type,
		xcas varchar2, --'1. 9. 2012 17:12:00'
		xdoma zapas.tim_doma%type,
		xvonku zapas.tim_vonku%type,
		xgoly_domaci zapas.goly_domaci%type default null,
		xgoly_vonku zapas.goly_vonku%type default null,
		xtyp zapas.typ_zapasu%type default null,
		xukoncenie zapas.ukoncenie_zapasu%type default null
		)
	as
		atyp number;
		aukoncenie number;
		atimestamp timestamp;
	begin
		select TO_TIMESTAMP ( xcas, 'DD. MM. YYYY HH24:MI:SS') into atimestamp from DUAL;

		if (xtyp is null) then
			atyp := 1;
		else
			atyp := xtyp;
		end if;

		if (xukoncenie is null) then
			aukoncenie := 1;
		else
			aukoncenie := xukoncenie;
		end if;

		if (xgoly_domaci is null or xgoly_vonku is null) then
			insert into zapas(mesto, cas, tim_doma, tim_vonku, goly_domaci, goly_vonku, typ_zapasu, ukoncenie_zapasu)
				values (xmesto, atimestamp, xdoma, xvonku, 0, 0, atyp, aukoncenie);
		else
			insert into zapas(mesto, cas, tim_doma, tim_vonku, goly_domaci, goly_vonku, typ_zapasu, ukoncenie_zapasu)
				values (xmesto, atimestamp, xdoma, xvonku, xgoly_domaci, xgoly_vonku, atyp, aukoncenie);
		end if;
	end;
end; --zapas_db
/
--exec ZAPAS_DB.PRIDAJ('Kupele', '1. 9. 2012 17:12:00', 1, 2);

--views
create or replace view V_zapasy as
	select z.id, t1.nazov nazov_doma, t2.nazov nazov_vonku, z.goly_domaci || ':' || z.goly_vonku skore, t_z.typ_zapasu_nazov, u_z.ukoncenie_zapasu_nazov
	from zapas z
	inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
	inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	inner join tim t1 on z.tim_doma = t1.id
	inner join tim t2 on z.tim_vonku = t2.id
;

create or replace view V_timy_body as
	select
  nazov as nazov,
  count(pocet_bodov) as body_spolu,
  count(vysledok) as zapasy,
  count(decode(vysledok, 'vyhra', '1')) as vyhry,
  count(decode(vysledok, 'prehra', '1')) as prehry,
  count(decode(vysledok, 'remiza', '1')) as remizy,
  count(decode(vysledok, 'vyhra v predlzeni', '1')) as vyhry_v_predlzeni,
  count(decode(vysledok, 'prehra v predlzeni', '1')) as prehry_v_predlzeni
  --SUM(longtable.pocet_bodov)
  --  OVER (PARTITION BY longtable.id_tymu
  --  ORDER BY longtable.id_tymu
  --  RANGE UNBOUNDED PRECEDING) pocet_bodov
  from
	((select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 3 pocet_bodov, 'vyhra' vysledok
		from zapas z
		inner join tim t on z.tim_doma = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI > z.GOLY_VONKU)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 3 pocet_bodov, 'vyhra' vysledok
		from zapas z
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join tim t on z.tim_vonku = t.id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI < z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU = 1)
	union all
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 0 pocet_bodov, 'prehra' vysledok
		from zapas z
		inner join tim t on z.tim_doma = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI < z.GOLY_VONKU)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 0 pocet_bodov, 'prehra' vysledok
		from zapas z
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join tim t on z.tim_vonku = t.id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI > z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU = 1)
	union all
	  (select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 1 pocet_bodov, 'remiza' vysledok
		from zapas z
		inner join tim t on z.tim_vonku = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI = z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU = 1)
	union all 
	  (select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 1 pocet_bodov, 'remiza' vysledok
		from zapas z
		inner join tim t on z.tim_doma = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI = z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU = 1)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 2 pocet_bodov, 'prehra v predlzeni' vysledok
		from zapas z
		inner join tim t on z.tim_doma = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI > z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU <> 1)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 2 pocet_bodov, 'prehra v predlzeni' vysledok
		from zapas z
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join tim t on z.tim_vonku = t.id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI < z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU <> 1)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 1 pocet_bodov, 'vyhra v predlzeni' vysledok
		from zapas z
		inner join tim t on z.tim_doma = t.id
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI < z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU <> 1)
	union all 
	(select z.id id, t.id id_tymu, t.nazov nazov, t_z.typ_zapasu_nazov typ, u_z.ukoncenie_zapasu_nazov ukoncenie, 1 pocet_bodov, 'vyhra v predlzeni' vysledok
		from zapas z
		inner join valid_typ_zapasu t_z on z.typ_zapasu = t_z.typ_zapasu_id
		inner join tim t on z.tim_vonku = t.id
		inner join valid_ukoncenie_zapasu u_z on z.ukoncenie_zapasu = u_z.ukoncenie_zapasu_id
	  where z.GOLY_DOMACI > z.GOLY_VONKU
	  and z.UKONCENIE_ZAPASU <> 1))
  group by nazov;

--testovacie data
INSERT INTO "TIM" (ID, NAZOV, GPS) VALUES ('1', 'Lev Praha', '100200');
INSERT INTO "TIM" (ID, NAZOV, GPS) VALUES ('2', 'Slovan Bratislava', '80200');


INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('1', 'Jaromir', 'Jagr', '2', '68', DATE '1972-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('2', 'Patrik', 'Elias', '3', '26', DATE '1974-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('3', 'Milan', 'Heduk', '1', '23', DATE '1973-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('4', 'Marek', 'Zidlicky', '4', '28', DATE '1977-02-03');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('5', 'Tomas', 'Kaberle', '4', '7', DATE '1978-03-02');

INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('6', 'Miroslav', 'Satan', '1', '18', DATE '1972-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('7', 'Peter', 'Bondra', '2', '12', DATE '1974-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('8', 'Marian', 'Gaborik', '3', '10', DATE '1973-02-15');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('9', 'Andrej', 'Sekera', '4', '28', DATE '1977-02-03');
INSERT INTO "HOKEJISTA" (ID, MENO, PRIEZVISKO, POZICIA, CISLO, DATUM_NARODENIA) VALUES ('10', 'Zdeno', 'Chara', '4', '7', DATE '1978-03-02');

INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('1', '1', '1', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('2', '2', '1', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('3', '3', '1', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('4', '4', '1', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('5', '5', '1', DATE '2005-01-01', DATE '2018-01-01', '1000');

INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('6', '6', '2', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('7', '7', '2', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('8', '8', '2', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('9', '9', '2', DATE '2005-01-01', DATE '2018-01-01', '1000');
INSERT INTO "KONTRAKT" (ID, HOKEJISTA, TIM, OD, DO, SUMA) VALUES ('10','10','2', DATE '2005-01-01', DATE '2018-01-01', '1000');

ZAPAS_DB.PRIDAJ('Praha', '1. 9. 2012 17:00:00', 1, 2);
ZAPAS_DB.PRIDAJ('Praha', '2. 9. 2012 17:00:00', 1, 2);
ZAPAS_DB.PRIDAJ('Praha', '4. 9. 2012 17:00:00', 1, 2);
ZAPAS_DB.PRIDAJ('Praha', '5. 9. 2012 17:00:00', 1, 2);
