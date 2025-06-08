CREATE OR ALTER FUNCTION dbo.removeMascaraCNPJ(@cnpj VARCHAR(20))
RETURNS VARCHAR(14)
AS
BEGIN
    DECLARE @result VARCHAR(14) = ''
    DECLARE @i INT = 1
    
    WHILE @i <= LEN(@cnpj) AND LEN(@result) < 14
    BEGIN
        DECLARE @char CHAR(1) = SUBSTRING(@cnpj, @i, 1)
        
        -- Mantém dígitos E letras (como no JavaScript original)
        IF (@char BETWEEN '0' AND '9') OR (@char BETWEEN 'A' AND 'Z') OR (@char BETWEEN 'a' AND 'z')
            SET @result = @result + UPPER(@char) -- Padroniza para maiúsculas
        -- Permite caracteres de máscara (., /, -) mas não os inclui no resultado
        ELSE IF @char NOT IN ('.', '/', '-')
            RETURN NULL -- Caractere inválido encontrado (não é dígito, letra ou máscara)
        
        SET @i = @i + 1
    END
    
    RETURN @result
END
GO

CREATE OR ALTER FUNCTION dbo.calculaDV(@cnpjBase VARCHAR(12))
RETURNS VARCHAR(2)
AS
BEGIN
    DECLARE @tamanhoCNPJSemDV INT = 12
    DECLARE @cnpjZerado VARCHAR(14) = '00000000000000'
    
    -- Verifica tamanho
    IF LEN(@cnpjBase) <> @tamanhoCNPJSemDV
        RETURN NULL
    
    -- Verifica se é igual aos primeiros 12 caracteres do CNPJ zerado
    IF @cnpjBase = LEFT(@cnpjZerado, @tamanhoCNPJSemDV)
        RETURN NULL
    
    -- Pesos (mesmo do JavaScript)
    DECLARE @pesosDV TABLE (pos INT IDENTITY(1,1), peso INT)
    INSERT INTO @pesosDV VALUES (6),(5),(4),(3),(2),(9),(8),(7),(6),(5),(4),(3),(2)
    
    DECLARE @somatorioDV1 INT = 0
    DECLARE @somatorioDV2 INT = 0
    DECLARE @i INT
    DECLARE @valorBase INT = ASCII('0')
    
    SET @i = 1
    WHILE @i <= @tamanhoCNPJSemDV
    BEGIN
        DECLARE @char CHAR(1) = SUBSTRING(@cnpjBase, @i, 1)
        DECLARE @valor INT
        
        -- Se for dígito, usa seu valor numérico
        IF @char BETWEEN '0' AND '9'
            SET @valor = ASCII(@char) - @valorBase
        -- Se for letra, usa o valor ASCII (como no JavaScript)
        ELSE
            SET @valor = ASCII(UPPER(@char)) - @valorBase
        
        -- Para DV1, usamos os pesos das posições 2 a 13
        SELECT @somatorioDV1 = @somatorioDV1 + (@valor * peso)
        FROM @pesosDV WHERE pos = @i + 1
        
        -- Para DV2, usamos os pesos das posições 1 a 12
        SELECT @somatorioDV2 = @somatorioDV2 + (@valor * peso)
        FROM @pesosDV WHERE pos = @i
        
        SET @i = @i + 1
    END
    
    DECLARE @dv1 INT = CASE WHEN @somatorioDV1 % 11 < 2 THEN 0 ELSE 11 - (@somatorioDV1 % 11) END
    
    -- Para o segundo DV, adicionamos o peso da posição 13
    SELECT @somatorioDV2 = @somatorioDV2 + (@dv1 * peso)
    FROM @pesosDV WHERE pos = 13
    
    DECLARE @dv2 INT = CASE WHEN @somatorioDV2 % 11 < 2 THEN 0 ELSE 11 - (@somatorioDV2 % 11) END
    
    RETURN CAST(@dv1 AS VARCHAR) + CAST(@dv2 AS VARCHAR)
END
GO

CREATE OR ALTER FUNCTION dbo.isValidCNPJ(@cnpj VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @tamanhoCNPJSemDV INT = 12
    DECLARE @cnpjZerado VARCHAR(14) = '00000000000000'
    
    DECLARE @cnpjSemMascara VARCHAR(14) = dbo.removeMascaraCNPJ(@cnpj)
    IF @cnpjSemMascara IS NULL OR LEN(@cnpjSemMascara) <> 14 OR @cnpjSemMascara = REPLICATE('0', 14)
        RETURN 0

    DECLARE @dvInformado VARCHAR(2) = SUBSTRING(@cnpjSemMascara, 13, 2)
    
    IF @dvInformado NOT LIKE '[0-9][0-9]'
        RETURN 0
    
    DECLARE @cnpjBase VARCHAR(12) = SUBSTRING(@cnpjSemMascara, 1, 12)
    DECLARE @dvCalculado VARCHAR(2) = dbo.calculaDV(@cnpjBase)
    
    IF @dvCalculado IS NULL
        RETURN 0
    
    IF @dvInformado = @dvCalculado
        RETURN 1

    RETURN 0
END
GO

SELECT dbo.isValidCNPJ('R1.JZX.TTK/0001-83') AS Valido
SELECT dbo.isValidCNPJ('03.248.373/0001-74') AS Valido
SELECT dbo.isValidCNPJ('8U.TYM.V11/0001-01') AS Valido
GO
