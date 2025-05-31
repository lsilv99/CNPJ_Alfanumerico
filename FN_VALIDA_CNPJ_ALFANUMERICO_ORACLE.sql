CREATE OR REPLACE FUNCTION removeMascaraCNPJ(p_cnpj IN VARCHAR2)
RETURN VARCHAR2
IS
    v_result VARCHAR2(14) := '';
    v_char CHAR(1);
BEGIN
    -- Remove apenas os caracteres de máscara, mantendo dígitos e letras
    FOR i IN 1..LENGTH(p_cnpj) LOOP
        v_char := UPPER(SUBSTR(p_cnpj, i, 1)); -- Converte para maiúsculas
        
        IF (v_char BETWEEN '0' AND '9') OR 
           (v_char BETWEEN 'A' AND 'Z') THEN
            v_result := v_result || v_char;
            
            -- Limita ao tamanho máximo de 14 caracteres
            IF LENGTH(v_result) = 14 THEN
                EXIT;
            END IF;
        ELSIF v_char NOT IN ('.', '/', '-') THEN
            -- Caractere inválido encontrado (não é dígito, letra ou máscara)
            RETURN NULL;
        END IF;
    END LOOP;
    
    -- Retorna NULL se não tiver pelo menos 14 caracteres válidos
    IF LENGTH(v_result) < 14 THEN
        RETURN NULL;
    END IF;
    
    RETURN v_result;
END removeMascaraCNPJ;
/

CREATE OR REPLACE FUNCTION calculaDV(p_cnpjBase IN VARCHAR2)
RETURN VARCHAR2
IS
    v_tamanhoCNPJSemDV NUMBER := 12;
    v_cnpjZerado VARCHAR2(14) := '00000000000000';
    
    TYPE t_pesos IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    v_pesos t_pesos;
    
    v_somatorioDV1 NUMBER := 0;
    v_somatorioDV2 NUMBER := 0;
    v_valorBase NUMBER := ASCII('0');
    v_char CHAR(1);
    v_valor NUMBER;
    v_dv1 NUMBER;
    v_dv2 NUMBER;
BEGIN
    -- Verifica tamanho
    IF LENGTH(p_cnpjBase) <> v_tamanhoCNPJSemDV THEN
        RETURN NULL;
    END IF;
    
    -- Verifica se é igual aos primeiros 12 caracteres do CNPJ zerado
    IF p_cnpjBase = SUBSTR(v_cnpjZerado, 1, v_tamanhoCNPJSemDV) THEN
        RETURN NULL;
    END IF;
    
    -- Inicializa pesos (posições 1 a 13)
    v_pesos(1) := 6;
    v_pesos(2) := 5;
    v_pesos(3) := 4;
    v_pesos(4) := 3;
    v_pesos(5) := 2;
    v_pesos(6) := 9;
    v_pesos(7) := 8;
    v_pesos(8) := 7;
    v_pesos(9) := 6;
    v_pesos(10) := 5;
    v_pesos(11) := 4;
    v_pesos(12) := 3;
    v_pesos(13) := 2;
    
    -- Calcula somatórios
    FOR i IN 1..v_tamanhoCNPJSemDV LOOP
        v_char := SUBSTR(p_cnpjBase, i, 1);
        
        -- Se for dígito, usa seu valor numérico
        IF v_char BETWEEN '0' AND '9' THEN
            v_valor := ASCII(v_char) - v_valorBase;
        -- Se for letra, usa o valor ASCII
        ELSE
            v_valor := ASCII(UPPER(v_char)) - v_valorBase;
        END IF;
        
        -- Para DV1, usamos os pesos das posições 2 a 13
        v_somatorioDV1 := v_somatorioDV1 + (v_valor * v_pesos(i + 1));
        
        -- Para DV2, usamos os pesos das posições 1 a 12
        v_somatorioDV2 := v_somatorioDV2 + (v_valor * v_pesos(i));
    END LOOP;
    
    -- Calcula DV1
    IF MOD(v_somatorioDV1, 11) < 2 THEN
        v_dv1 := 0;
    ELSE
        v_dv1 := 11 - MOD(v_somatorioDV1, 11);
    END IF;
    
    -- Para o segundo DV, adicionamos o peso da posição 13
    v_somatorioDV2 := v_somatorioDV2 + (v_dv1 * v_pesos(13));
    
    -- Calcula DV2
    IF MOD(v_somatorioDV2, 11) < 2 THEN
        v_dv2 := 0;
    ELSE
        v_dv2 := 11 - MOD(v_somatorioDV2, 11);
    END IF;
    
    RETURN TO_CHAR(v_dv1) || TO_CHAR(v_dv2);
END calculaDV;
/

CREATE OR REPLACE FUNCTION isValidCNPJ(p_cnpj IN VARCHAR2)
RETURN NUMBER
IS
    v_cnpjSemMascara VARCHAR2(14);
    v_dvInformado VARCHAR2(2);
    v_cnpjBase VARCHAR2(12);
    v_dvCalculado VARCHAR2(2);
BEGIN
    -- Remove máscara e verifica caracteres inválidos
    v_cnpjSemMascara := removeMascaraCNPJ(p_cnpj);

    IF v_cnpjSemMascara IS NULL THEN
        RETURN 0;
    END IF;

    -- Verifica tamanho
    IF LENGTH(v_cnpjSemMascara) <> 14 THEN
        RETURN 0;
    END IF;

    -- Verifica se é CNPJ zerado
    IF v_cnpjSemMascara = '00000000000000' THEN
        RETURN 0;
    END IF;

    -- Pega os dígitos verificadores informados
    v_dvInformado := SUBSTR(v_cnpjSemMascara, 13, 2);

    -- Verifica se os DVs são numéricos
    IF NOT REGEXP_LIKE(v_dvInformado, '^[0-9]{2}$') THEN
        RETURN 0;
    END IF;

    -- Pega os 12 primeiros caracteres para cálculo
    v_cnpjBase := SUBSTR(v_cnpjSemMascara, 1, 12);

    -- Calcula o DV esperado
    v_dvCalculado := calculaDV(v_cnpjBase);

    IF v_dvCalculado IS NULL THEN
        RETURN 0;
    END IF;

    -- Compara com o DV informado
    IF v_dvInformado = v_dvCalculado THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END isValidCNPJ;

SELECT 
    removeMascaraCNPJ('S9.QID.0XE/0001-90') AS cnpj_sem_mascara,
    isValidCNPJ('S9.QID.0XE/0001-90') AS valido
FROM dual;
