﻿CREATE TABLE [dbo].[GrilaPretCentrColectLapte] (
    [Centru_colectare] CHAR (9)   NOT NULL,
    [Tip_lapte]        CHAR (20)  NOT NULL,
    [Data_lunii]       DATETIME   NOT NULL,
    [Tip_plata]        CHAR (1)   NOT NULL,
    [Pret]             FLOAT (53) NOT NULL,
    [Cantitate]        FLOAT (53) NOT NULL,
    [Procent]          REAL       NOT NULL,
    [UM]               CHAR (3)   NOT NULL,
    [Data_operarii]    DATETIME   NOT NULL,
    [Ora_operarii]     CHAR (6)   NOT NULL,
    [Utilizator]       CHAR (10)  NOT NULL,
	coloana_noua varchar(50), 
    [coloana_mea] NCHAR(10) NULL
);


GO
CREATE NONCLUSTERED INDEX [missing_index_7892]
    ON [dbo].[GrilaPretCentrColectLapte]([Data_lunii] ASC)
    INCLUDE([Centru_colectare], [Tip_lapte], [Tip_plata]);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[GrilaPretCentrColectLapte]([Centru_colectare] ASC, [Tip_lapte] ASC, [Data_lunii] ASC) WITH (FILLFACTOR = 80);

