-- Tabela temporária para substituir a função que usava RAND()
CREATE OR ALTER PROCEDURE dbo.GerarCNPJsAlfanumericos
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tabela para armazenar os CNPJs gerados
    CREATE TABLE #CNPJsGerados (
        ID INT IDENTITY(1,1), 
        CNPJ VARCHAR(20), 
        CNPJ_Formatado VARCHAR(20)
    );
    
    -- Tabela com caracteres permitidos
    DECLARE @chars TABLE (pos INT IDENTITY(1,1), char CHAR(1));
    INSERT INTO @chars VALUES 
        ('0'),('1'),('2'),('3'),('4'),('5'),('6'),('7'),('8'),('9'),
        ('A'),('B'),('C'),('D'),('E'),('F'),('G'),('H'),('I'),('J'),
        ('K'),('L'),('M'),('N'),('O'),('P'),('Q'),('R'),('S'),('T'),
        ('U'),('V'),('W'),('X'),('Y'),('Z');
    
    DECLARE @contador INT = 0;
    DECLARE @baseCNPJ VARCHAR(12);
    DECLARE @dv VARCHAR(2);
    DECLARE @cnpjSemMascara VARCHAR(14);
    DECLARE @cnpjFormatado VARCHAR(20);
    DECLARE @i INT;
    DECLARE @randomIndex INT;
    
    WHILE @contador < 100
    BEGIN
        -- Gera base do CNPJ (8 caracteres alfanuméricos + 0001)
        SET @baseCNPJ = '';
        SET @i = 1;
        
        WHILE @i <= 8
        BEGIN
            -- Gera índice aleatório entre 1 e 36
            SET @randomIndex = CAST(CEILING(RAND() * 36) AS INT);
            
            -- Obtém caractere aleatório
            SELECT @baseCNPJ = @baseCNPJ + char 
            FROM @chars 
            WHERE pos = CASE WHEN @randomIndex = 0 THEN 1 ELSE @randomIndex END;
            
            SET @i = @i + 1;
        END
        
        SET @baseCNPJ = @baseCNPJ + '0001';
        
        -- Calcula dígitos verificadores
        SET @dv = dbo.calculaDV(@baseCNPJ);
        
        -- Se o DV for válido, formata e armazena
        IF @dv IS NOT NULL AND LEN(@baseCNPJ) = 12
        BEGIN
            SET @cnpjSemMascara = @baseCNPJ + @dv;
            
            -- Formatação com máscara
            SET @cnpjFormatado = 
                SUBSTRING(@cnpjSemMascara, 1, 2) + '.' +
                SUBSTRING(@cnpjSemMascara, 3, 3) + '.' +
                SUBSTRING(@cnpjSemMascara, 6, 3) + '/' +
                SUBSTRING(@cnpjSemMascara, 9, 4) + '-' +
                SUBSTRING(@cnpjSemMascara, 13, 2);
            
            INSERT INTO #CNPJsGerados (CNPJ, CNPJ_Formatado)
            VALUES (@cnpjSemMascara, @cnpjFormatado);
            
            SET @contador = @contador + 1;
        END
    END
    
    -- Retorna os CNPJs gerados
    SELECT 
        ID,
        CNPJ AS 'CNPJ_Sem_Mascara',
        CNPJ_Formatado AS 'CNPJ_Formatado',
        dbo.isValidCNPJ(CNPJ) AS 'Valido'
    FROM #CNPJsGerados
    ORDER BY ID;
    
    DROP TABLE #CNPJsGerados;
END
GO

-- Executa a geração dos CNPJs
EXEC dbo.GerarCNPJsAlfanumericos;
