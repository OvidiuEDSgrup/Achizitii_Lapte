﻿CREATE TABLE dbo.AL_Producatori (
    id_prod          INT NOT NULL
		DEFAULT (NEXT VALUE FOR AL_Producatori_ID_prod)
		CONSTRAINT PK_AL_Producatori 
			PRIMARY KEY CLUSTERED (id_prod ASC),
    cod_prod         VARCHAR (36)    NULL,
    denumire         VARCHAR (50)    NOT NULL,
    initiala_tata    CHAR (1)        NOT NULL,
    CNP_CUI          VARCHAR (15)    NOT NULL,
    serie_BI         CHAR (2)        NOT NULL,
    nr_BI            CHAR (7)        NOT NULL,
    elib_BI          VARCHAR (20)    NOT NULL,
    cod_jud          VARCHAR (3)     NULL
		CONSTRAINT FK_AL_Producatori_Judete 
			FOREIGN KEY (cod_jud) REFERENCES dbo.Judete (cod_judet),
    cod_loc          VARCHAR (8)     NULL
		CONSTRAINT FK_AL_Producatori_Localitati 
			FOREIGN KEY (cod_loc) REFERENCES dbo.Localitati (cod_oras),
    cod_tara         VARCHAR (3)     NULL
		CONSTRAINT FK_AL_Producatori_Tari 
			FOREIGN KEY (cod_tara) REFERENCES dbo.Tari (cod_tara),
    comuna           VARCHAR (30)    NOT NULL,
    sat              VARCHAR (30)    NOT NULL,
    strada           VARCHAR (30)    NOT NULL,
    nr_str           VARCHAR (5)     NOT NULL,
    nr_casa          VARCHAR (10)    NOT NULL,
    bloc             VARCHAR (10)    NOT NULL,
    scara            VARCHAR (10)    NOT NULL,
    etaj             VARCHAR (10)    NOT NULL,
    ap               VARCHAR (5)     NOT NULL,
    cod_exploatatie  VARCHAR (15)    NOT NULL,
    cota_actuala     DECIMAL (12, 2) NOT NULL,
    grad_actual      DECIMAL (7, 3)  NOT NULL,
    nr_contr         VARCHAR (20)    NULL,
    data_contr       DATETIME2 (0)   NULL,
    valabil_contr    DATETIME2 (0)   NULL,
    cant_contr       DECIMAL (12, 2) NOT NULL,
    nr_vaci          SMALLINT        NOT NULL,
    grupa            CHAR (1)        NOT NULL,
    pret             DECIMAL (12, 2) NOT NULL,
    bonus            TINYINT         NOT NULL,
    tip_pers         CHAR (1)        NOT NULL,
    subunit          VARCHAR (9)     NULL,
    tert             VARCHAR (13)    NULL,
    reprezentant     VARCHAR (30)    NOT NULL,
    CNP_repr         VARCHAR (13)    NOT NULL,
    id_centru        INT             NULL,
    loc_munca        VARCHAR (9)     NOT NULL,
    DACL             TINYINT         NOT NULL,
    tip_furnizor     CHAR (1)        NOT NULL,
    cont_banca       VARCHAR (35)    NOT NULL DEFAULT (''),
    banca            VARCHAR (20)    NOT NULL,
    data_operarii    DATETIME2 (3)   NOT NULL,
    operator         VARCHAR (10)    NULL
		CONSTRAINT FK_AL_Producatori_Utilizatori 
			FOREIGN KEY (operator) REFERENCES dbo.utilizatori (ID),
    detalii          XML             NULL,
    CONSTRAINT FK_AL_Producatori_Terti 
		FOREIGN KEY (subunit, tert) REFERENCES dbo.terti (Subunitate, Tert),
    CONSTRAINT CK_AL_Prod_Loc_Jud_Tara_Completate 
		CHECK (coalesce(cod_loc,cod_jud,cod_tara) IS NOT NULL)
);

GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_AL_Producatori
    ON dbo.AL_Producatori(denumire ASC, initiala_tata ASC, CNP_CUI ASC);






GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'backward compatibility ASISold', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'AL_Producatori', @level2type = N'COLUMN', @level2name = N'cod_prod';

