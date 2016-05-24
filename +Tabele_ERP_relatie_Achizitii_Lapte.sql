/*
   Tuesday, May 24, 20164:50:17 PM
   User: 
   Server: BSERVER
   Database: AL
   Application: 
*/

/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Localitati
	(
	cod_oras varchar(8) NOT NULL,
	cod_judet char(3) NOT NULL,
	tip_oras char(8) NOT NULL,
	oras char(30) NOT NULL,
	cod_postal char(10) NOT NULL,
	extern bit NOT NULL,
	coord geography NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Localitati SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Localitati)
	 EXEC('INSERT INTO dbo.Tmp_Localitati (cod_oras, cod_judet, tip_oras, oras, cod_postal, extern, coord)
		SELECT CONVERT(varchar(8), cod_oras), cod_judet, tip_oras, oras, cod_postal, extern, coord FROM dbo.Localitati WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Localitati
GO
EXECUTE sp_rename N'dbo.Tmp_Localitati', N'Localitati', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX cod_localitate ON dbo.Localitati
	(
	cod_oras
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX judet_oras ON dbo.Localitati
	(
	cod_judet,
	tip_oras,
	oras
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Lm
	DROP CONSTRAINT DF__lm__uidlinie__590AFA22
GO
CREATE TABLE dbo.Tmp_Lm
	(
	Nivel smallint NOT NULL,
	Cod varchar(9) NOT NULL,
	Cod_parinte char(9) NOT NULL,
	Denumire char(30) NOT NULL,
	detalii xml NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Lm SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Lm)
	 EXEC('INSERT INTO dbo.Tmp_Lm (Nivel, Cod, Cod_parinte, Denumire, detalii)
		SELECT Nivel, CONVERT(varchar(9), Cod), Cod_parinte, Denumire, detalii FROM dbo.Lm WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Lm
GO
EXECUTE sp_rename N'dbo.Tmp_Lm', N'Lm', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX Cod ON dbo.Lm
	(
	Cod
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX Denumire ON dbo.Lm
	(
	Denumire
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX Principal ON dbo.Lm
	(
	Nivel,
	Cod
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
create  trigger tr_ValidLM on dbo.Lm for update, delete NOT FOR REPLICATION as
begin try
	/** 
		Cazul stergerilor 
			- nu se permite stergerea unui loc de munca parinte sau a unui loc de munca cu documente 	
	**/
	IF EXISTS (SELECT 1 from DELETED) and NOT EXISTS( select 1 from inserted)
	begin
		IF EXISTS (select 1 from DELETED d join lm l on d.Cod=l.Cod_parinte)
			RAISERROR ('Nu puteti sterge un loc de munca parinte!', 16, 1)
		IF EXISTS (select 1 from DELETED d join pozincon p on d.Cod=p.Loc_de_munca)
			RAISERROR ('Nu puteti sterge un loc de munca pe care exista documente!', 16, 1)
	end

	/** 
		Actualizari
			- daca locul de munca este parinte pt altele nu se pot actualiza codul si nivelul
			- daca locul de munca are documente nu permite actualizare codului	
	**/
	IF EXISTS (select 1 from DELETED) and EXISTS (select 1 from INSERTED)
	BEGIN
		IF (NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod) OR NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod and i.nivel=d.nivel) )
			and exists (select 1 from DELETED d join lm l on d.Cod=l.Cod_parinte)
			RAISERROR ('Nu puteti actualiza codul si nivelul unui loc de munca parinte!', 16, 1)
		
		IF NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod) 
			and exists (select 1 from DELETED d join pozincon p on d.Cod=p.Loc_de_munca)
			RAISERROR ('Nu puteti actualiza codul unui loc de munca pe care exista documente!', 16, 1)
	end
end try

begin catch
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror(@mesaj, 16, 1)
end catch
GO
--***
CREATE trigger lmsterg on dbo.Lm for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssl
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Nivel, Cod, Cod_parinte, Denumire
   from deleted
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Judete
	(
	cod_judet varchar(3) NOT NULL,
	denumire char(30) NOT NULL,
	prefix_telefonic char(4) NOT NULL,
	coord geography NULL,
	resedinta varchar(8) NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Judete SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Judete)
	 EXEC('INSERT INTO dbo.Tmp_Judete (cod_judet, denumire, prefix_telefonic, coord, resedinta)
		SELECT CONVERT(varchar(3), cod_judet), denumire, prefix_telefonic, coord, resedinta FROM dbo.Judete WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Judete
GO
EXECUTE sp_rename N'dbo.Tmp_Judete', N'Judete', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX cod_judet ON dbo.Judete
	(
	cod_judet
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX denumire ON dbo.Judete
	(
	denumire
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Terti
	DROP CONSTRAINT DF__terti__uidlinie__553A693E
GO
CREATE TABLE dbo.Tmp_Terti
	(
	Subunitate varchar(9) NOT NULL,
	Tert varchar(13) NOT NULL,
	Denumire char(80) NOT NULL,
	Cod_fiscal char(16) NOT NULL,
	Localitate char(35) NOT NULL,
	Judet char(20) NOT NULL,
	Adresa char(60) NOT NULL,
	Telefon_fax char(20) NOT NULL,
	Banca char(20) NOT NULL,
	Cont_in_banca char(35) NOT NULL,
	Tert_extern bit NOT NULL,
	Grupa char(3) NOT NULL,
	Cont_ca_furnizor varchar(20) NULL,
	Cont_ca_beneficiar varchar(20) NULL,
	Sold_ca_furnizor float(53) NOT NULL,
	Sold_ca_beneficiar float(53) NOT NULL,
	Sold_maxim_ca_beneficiar float(53) NOT NULL,
	Disccount_acordat real NOT NULL,
	detalii xml NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Terti SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Terti)
	 EXEC('INSERT INTO dbo.Tmp_Terti (Subunitate, Tert, Denumire, Cod_fiscal, Localitate, Judet, Adresa, Telefon_fax, Banca, Cont_in_banca, Tert_extern, Grupa, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, Sold_maxim_ca_beneficiar, Disccount_acordat, detalii)
		SELECT CONVERT(varchar(9), Subunitate), CONVERT(varchar(13), Tert), Denumire, Cod_fiscal, Localitate, Judet, Adresa, Telefon_fax, Banca, Cont_in_banca, Tert_extern, Grupa, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, Sold_maxim_ca_beneficiar, Disccount_acordat, detalii FROM dbo.Terti WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Terti
GO
EXECUTE sp_rename N'dbo.Tmp_Terti', N'Terti', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX Principal ON dbo.Terti
	(
	Subunitate,
	Tert
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX Cod_fiscal ON dbo.Terti
	(
	Cod_fiscal
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX Denumire ON dbo.Terti
	(
	Denumire
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX _dta_index_terti_11_1413891333__K2_K1_3_4_5_6_7_9_10 ON dbo.Terti
	(
	Tert,
	Subunitate
	) INCLUDE (Denumire, Cod_fiscal, Localitate, Judet, Adresa, Banca, Cont_in_banca) 
 WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX missing_index_2199 ON dbo.Terti
	(
	Subunitate,
	Denumire
	) INCLUDE (Tert, Cod_fiscal, Localitate, Judet, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, Sold_maxim_ca_beneficiar, Disccount_acordat, Adresa, Telefon_fax, Banca, Cont_in_banca, Tert_extern, Grupa) 
 WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX _dta_index_terti_7_1413891333__K1_K2_3_5_12 ON dbo.Terti
	(
	Subunitate,
	Tert
	) INCLUDE (Denumire, Localitate, Grupa) 
 WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
--***
CREATE trigger tertisterg on dbo.Terti for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysst
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate, Tert, Denumire, Cod_fiscal, Localitate, Judet, Adresa, Telefon_fax, Banca, Cont_in_banca, 
	Tert_extern, Grupa, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, 
	Sold_maxim_ca_beneficiar, Disccount_acordat
   from deleted
GO
create trigger tr_validTert on dbo.Terti for update, delete not for replication as
begin try
	/** 
		Cazul stergerilor 
			- nu se permite stergerea unei cocomenzi daca exista documente pe comanda respectiva
	**/
	if exists (select 1 from deleted) and not exists(select 1 from inserted)
	begin
		if exists(select 1 from DELETED d join pozdoc p on d.Subunitate=p.subunitate and d.tert=p.Tert)
			raiserror ('Nu puteti sterge un tert pe care exista documente!', 16, 1)
	end

	/** 
		Cazul actualizari
			- daca comanda are documente nu permite actualizarea comenzii
	**/
	if exists(select 1 from DELETED) and exists(select 1 from INSERTED)
	begin
		if not exists (select 1 from DELETED d join INSERTED i on d.Subunitate=i.Subunitate and d.tert=i.tert) 
			and exists (select 1 from DELETED d join pozdoc p on d.Subunitate=p.Subunitate and d.tert=p.tert)
			raiserror ('Nu puteti actualiza un tert pe care exista documente!', 16, 1)
	end
end try

begin catch
	rollback transaction
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror(@mesaj, 16, 1)
end catch
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Utilizatori
	(
	ID varchar(10) NOT NULL,
	Nume char(30) NOT NULL,
	Parola char(10) NOT NULL,
	Info char(100) NOT NULL,
	Categoria smallint NOT NULL,
	Jurnal char(3) NOT NULL,
	Marca char(6) NOT NULL,
	Observatii char(30) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Utilizatori SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Utilizatori)
	 EXEC('INSERT INTO dbo.Tmp_Utilizatori (ID, Nume, Parola, Info, Categoria, Jurnal, Marca, Observatii)
		SELECT CONVERT(varchar(10), ID), Nume, Parola, Info, Categoria, Jurnal, Marca, Observatii FROM dbo.Utilizatori WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Utilizatori
GO
EXECUTE sp_rename N'dbo.Tmp_Utilizatori', N'Utilizatori', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX ID ON dbo.Utilizatori
	(
	ID
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 80, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
--***
create trigger tr_modif_utilizator on dbo.Utilizatori for update, delete
as
declare @eroare varchar(2000)
begin try
	declare @updatat varchar(10), @anterior varchar(10), @ria int, @inserate int, @sterse int, @modifCod int
	select @ria=1, @inserate=0, @sterse=0, @modifCod=0
		--> se verifica daca e tip ria (adica daca exista tabele ria); proprietatile trebuie mentinute si pe partea de ASiSplus
	if not exists (select 1 from sysobjects s where s.name='webConfigMeniuUtiliz') or
		not exists (select 1 from sysobjects s where s.name='webConfigRapoarte')
	select @ria=0

	select @inserate=count(1) from inserted i
	select @sterse=count(1) from deleted d
	select @modifCod=count(1) from inserted i where not exists (select 1 from deleted d where d.id=i.id)
	
	if (@inserate>1 or @inserate>0 and @sterse>1) and @modifCod>=1
		raiserror('Nu e permisa modificarea masiva a codurilor de utilizatori deoarece nu se poate mentine integritatea configurarilor! Modificati codurile pentru fiecare utilizator pe rand!',16,1)
	
	select @updatat=i.ID from inserted i where @inserate>0 and not exists (select 1 from deleted d where d.ID=i.ID)
	select @anterior=d.ID from deleted d
	
	if @updatat is not null
	begin
		if @ria=1
			update w set IdUtilizator=@updatat
			from webConfigMeniuUtiliz w where w.IdUtilizator=@anterior
		
		if @ria=1
			update r set utilizator=@updatat
			from webConfigRapoarte r where r.utilizator=@anterior
		
		update p set cod=@updatat
		from proprietati p where p.Cod=@anterior and p.Tip='UTILIZATOR'
	end
	else
	if @modifCod=0
	begin
		if @ria=1
			delete w from webConfigMeniuUtiliz w inner join deleted d on w.IdUtilizator=d.ID
				where not exists (select 1 from inserted i where i.id=d.id)
		if @ria=1
			delete r from webConfigRapoarte r inner join deleted d on r.utilizator=d.ID
				where not exists (select 1 from inserted i where i.id=d.id)
		delete p from proprietati p inner join deleted d on p.Cod=d.ID and p.Tip='UTILIZATOR'
			where not exists (select 1 from inserted i where i.id=d.id)
	end
end try
begin catch
	set @eroare=ERROR_MESSAGE()+char(13)+'(tr_modif_utilizator)'
	raiserror(@eroare,16,1)
end catch
GO
--***
create  trigger tr_validUtilizator on dbo.Utilizatori for insert,update NOT FOR REPLICATION as
begin
	declare @eroare varchar(1000)
	set @eroare=''
	begin try
		
		--if exists (select 1 from utilizatori u where u.ID<>inserted.id and u.Observatii=inserted.observatii)
			select @eroare='Utilizatorul Windows "'+rtrim(i.observatii)+'" este deja folosit pentru utilizatorul "'+rtrim(u.id)+'" !'
				from utilizatori u, inserted i 
				where u.ID<>i.id and u.Observatii=i.observatii and i.Observatii<>''
			if len(@eroare)>0 raiserror(@eroare,16,1)
	end try
	begin catch
		set @eroare=@eroare+char(13)+'(tr_validUtilizator)'
		raiserror (@eroare,16,1)
	end catch
end
GO
CREATE TRIGGER wTrigRia 
ON dbo.Utilizatori
FOR INSERT, UPDATE, DELETE
AS
		-- sterg din ASiSria..utilizatoriRia, utilizatorii modficati.
	DELETE u FROM ASiSRIA.dbo.utilizatoriRIA u
	WHERE u.bd = db_name() 
	and ( EXISTS (SELECT 1 FROM DELETED d WHERE d.id = u.utilizator ) -- utilizatori modificati
		-- sterg si utilizatorii care tomai se insereaza - ar putea sa existe deja in tabela 
		-- utilizatoriRIA, daca se face un backup/restore si se readauga aceeasi useri.
		or EXISTS (SELECT 1 FROM INSERTED d WHERE d.id = u.utilizator ) ) 
	
	-- inserez in ASiSria..utilizatoriRia, utilizatorii modficati.
	INSERT INTO ASiSRIA.dbo.utilizatoriRIA(bd,utilizator,parola,utilizatorWindows)
	SELECT db_name(),RTRIM(id),RTRIM(info),RTRIM(observatii)
	FROM INSERTED where inserted.id<>''

	-- actualizez parola pentru utilizator - un user poate avea o singura parola MD5 aici
	-- 2011-08-15 - mitz - permitem sa aiba parole diferite pe baze de date diferite... se va trata si in web service...
	/*update ASiSRIA.dbo.utilizatoriRIA 
	set parola=rtrim(i.info)
	from inserted i , ASiSRIA.dbo.utilizatoriRIA u
	where i.ID=u.utilizator and u.BD<>DB_NAME()*/
GO
COMMIT
BEGIN TRANSACTION
GO
CREATE TABLE dbo.Tmp_Tari
	(
	cod_tara varchar(3) NOT NULL,
	denumire char(200) NOT NULL,
	prefix_telefonic char(4) NOT NULL,
	Teritoriu char(1) NOT NULL,
	Val1 float(53) NOT NULL,
	Data datetime NOT NULL,
	Detalii char(200) NOT NULL,
	Continent varchar(1) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Tmp_Tari SET (LOCK_ESCALATION = TABLE)
GO
IF EXISTS(SELECT * FROM dbo.Tari)
	 EXEC('INSERT INTO dbo.Tmp_Tari (cod_tara, denumire, prefix_telefonic, Teritoriu, Val1, Data, Detalii, Continent)
		SELECT CONVERT(varchar(3), cod_tara), denumire, prefix_telefonic, Teritoriu, Val1, Data, Detalii, Continent FROM dbo.Tari WITH (HOLDLOCK TABLOCKX)')
GO
DROP TABLE dbo.Tari
GO
EXECUTE sp_rename N'dbo.Tmp_Tari', N'Tari', 'OBJECT' 
GO
CREATE UNIQUE CLUSTERED INDEX cod_tara ON dbo.Tari
	(
	cod_tara
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX denumire ON dbo.Tari
	(
	denumire
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
COMMIT
