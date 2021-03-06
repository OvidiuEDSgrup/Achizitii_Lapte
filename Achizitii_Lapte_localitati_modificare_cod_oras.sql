/*
   Tuesday, May 17, 20163:13:15 PM
   User: 
   Server: SERVER-ASIS
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
	cod_judet varchar(3) NOT NULL,
	tip_oras varchar(8) NOT NULL,
	oras varchar(30) NOT NULL,
	cod_postal varchar(10) NOT NULL,
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
